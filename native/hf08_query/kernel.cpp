#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <cmath>
#include <cstdint>
#include <unordered_map>
#include <vector>
using namespace godot;
#include "obstacle_kernel.hpp"

// Experimental immutable exact kernel. The original validated Godot geometry
// and ordered cell slots remain the configuration authority.
class HF08SupportKernel : public RefCounted {
 GDCLASS(HF08SupportKernel, RefCounted)
 struct Triangle { Vector2 a,b,c; Vector3 heights; double denominator; int surface; };
 std::vector<Triangle> triangles;
 std::vector<String> surfaces;
 std::unordered_map<uint64_t,std::vector<int>> cells;
 bool configured=false;
 mutable uint64_t evaluations=0,batch_calls=0,batch_samples=0;
 mutable uint64_t fused_calls=0,fused_planned=0,fused_visited=0,fused_body=0,fused_slope=0,fused_support_reject=0,fused_body_reject=0,fused_slope_reject=0,fused_fallback=0;
 struct Result { int code; const char *reason; int surface=-1; double height=0.; std::vector<int> ambiguous; };
 int find_surface(const String &id) const {
  if(id.is_empty())return -1;
  for(size_t i=0;i<surfaces.size();++i)if(surfaces[i]==id)return int(i);
  return -2;
 }
 Result evaluate(Vector2 p,int wanted) const {
  ++evaluations;
  if(!configured || !p.is_finite())return {ERR_INVALID_PARAMETER,nullptr};
  if(wanted==-2)return {ERR_DOES_NOT_EXIST,"NO_TAGGED_SUPPORT"};
  const auto found=cells.find(cell_key(int32_t(std::floor(double(p.x))),int32_t(std::floor(double(p.y)))));
  if(found==cells.end())return {ERR_DOES_NOT_EXIST,"NO_TAGGED_SUPPORT"};
  std::vector<std::pair<int,double>> hits;hits.reserve(2);
  for(int slot:found->second) {
   const Triangle &t=triangles[slot];if(wanted>=0 && t.surface!=wanted)continue;
   const double u=double((t.b-p).cross(t.c-p))/t.denominator;
   const double v=double((t.c-p).cross(t.a-p))/t.denominator;
   const double w=1.0-u-v;
   if(minimum(u,minimum(v,w))<-.00001)continue;
   const double y=double(t.heights.x)*u+double(t.heights.y)*v+double(t.heights.z)*w;
   bool existing=false;
   for(auto &hit:hits)if(hit.first==t.surface) {
    if(std::abs(hit.second-y)>.001)return {ERR_INVALID_DATA,"MULTIPLE_HEIGHTS_IN_ONE_SURFACE"};
    hit.second=y;existing=true;break;
   }
   if(!existing)hits.emplace_back(t.surface,y);
  }
  if(hits.empty())return {ERR_DOES_NOT_EXIST,"NO_TAGGED_SUPPORT"};
  if(hits.size()!=1)for(const auto &hit:hits)if(std::abs(hit.second-hits[0].second)>.001) {
   Result r{ERR_INVALID_DATA,"EXPLICIT_SURFACE_REQUIRED"};
   for(const auto &row:hits)r.ambiguous.push_back(row.first);return r;
  }
  return {OK,nullptr,hits[0].first,hits[0].second};
 }
 static uint64_t cell_key(int32_t x,int32_t y) { return (uint64_t(uint32_t(x))<<32)|uint32_t(y); }
 static Dictionary error(int code,const char *reason=nullptr) {
  Dictionary d;d["error"]=code;if(reason)d["reason"]=String(reason);return d;
 }
 static double minimum(double a,double b) { return a<b?a:b; }
protected:
 static void _bind_methods() {
  ClassDB::bind_method(D_METHOD("configure","triangles","cells"),&HF08SupportKernel::configure);
  ClassDB::bind_method(D_METHOD("support","point","surface_id"),&HF08SupportKernel::support);
  ClassDB::bind_method(D_METHOD("segment_support","a","b","steps","from","to"),&HF08SupportKernel::segment_support);
  ClassDB::bind_method(D_METHOD("travel_fused","a","b","steps","from","to","radius","height","gates","obstacles"),&HF08SupportKernel::travel_fused);
  ClassDB::bind_method(D_METHOD("reset_profile"),&HF08SupportKernel::reset_profile);
  ClassDB::bind_method(D_METHOD("statistics"),&HF08SupportKernel::statistics);
 }
public:
 int configure(const Array &rows,const Dictionary &source_cells) {
  if(configured)return ERR_ALREADY_IN_USE;
  static_assert(sizeof(real_t)==4,"This kernel is explicitly single-precision-vector only");
  triangles.clear();surfaces.clear();cells.clear();
  triangles.reserve(rows.size());
  for(int64_t i=0;i<rows.size();++i) {
   if(rows[i].get_type()!=Variant::DICTIONARY)return ERR_INVALID_DATA;
   Dictionary row=rows[i];
   if(!row.has("surface_id") || !row.has("a") || !row.has("b") || !row.has("c") || !row.has("denominator"))return ERR_INVALID_DATA;
   if(Variant(row["surface_id"]).get_type()!=Variant::STRING || Variant(row["a"]).get_type()!=Variant::VECTOR3 || Variant(row["b"]).get_type()!=Variant::VECTOR3 || Variant(row["c"]).get_type()!=Variant::VECTOR3)return ERR_INVALID_DATA;
   const auto denominator_type=Variant(row["denominator"]).get_type();
   if(denominator_type!=Variant::FLOAT && denominator_type!=Variant::INT)return ERR_INVALID_DATA;
   String id=row["surface_id"];int surface=-1;
   for(size_t j=0;j<surfaces.size();++j)if(surfaces[j]==id){surface=int(j);break;}
   if(surface<0){surface=int(surfaces.size());surfaces.push_back(id);}
   Vector3 a=row["a"],b=row["b"],c=row["c"];
   triangles.push_back({Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z),Vector3(a.y,b.y,c.y),double(row["denominator"]),surface});
  }
  Array keys=source_cells.keys();cells.reserve(keys.size());
  for(int64_t i=0;i<keys.size();++i) {
   if(keys[i].get_type()!=Variant::VECTOR2I)return ERR_INVALID_DATA;
   Vector2i key=keys[i];if(Variant(source_cells[key]).get_type()!=Variant::ARRAY)return ERR_INVALID_DATA;
   Array slots=source_cells[key];auto &out=cells[cell_key(key.x,key.y)];out.reserve(slots.size());
   for(int64_t j=0;j<slots.size();++j) {
    if(slots[j].get_type()!=Variant::INT)return ERR_INVALID_DATA;
    const int64_t slot=slots[j];if(slot<0 || slot>=int64_t(triangles.size()))return ERR_INVALID_DATA;
    out.push_back(int(slot));
   }
  }
  configured=true;return OK;
 }
 Dictionary support(Vector2 p,const String &surface_id) const {
  const Result r=evaluate(p,find_surface(surface_id));
  if(r.code!=OK) {
   Dictionary d=error(r.code,r.reason);
   if(!r.ambiguous.empty()){Array ids;for(int id:r.ambiguous)ids.append(surfaces[id]);d["surfaces"]=ids;}
   return d;
  }
  Dictionary d;d["error"]=OK;d["surface_id"]=surfaces[r.surface];d["position"]=Vector3(p.x,real_t(r.height),p.y);return d;
 }
 Dictionary segment_support(Vector2 a,Vector2 b,int64_t steps,const String &from,const String &to) const {
  if(!configured || !a.is_finite() || !b.is_finite() || steps<1 || steps>65536 || std::abs(a.x)>2147480000. || std::abs(a.y)>2147480000. || std::abs(b.x)>2147480000. || std::abs(b.y)>2147480000.)return error(ERR_INVALID_PARAMETER);
  ++batch_calls;batch_samples+=uint64_t(steps+1);
  PackedVector2Array points;PackedVector3Array positions;PackedInt32Array errors;
  points.resize(steps+1);positions.resize(steps+1);errors.resize(steps+1);
  auto *pp=points.ptrw();auto *hp=positions.ptrw();auto *ep=errors.ptrw();
  const int from_id=find_surface(from),to_id=find_surface(to);
  for(int64_t step=0;step<=steps;++step) {
   // Match GDScript float(step)/steps (double), then the Vector2 lerp ABI's
   // real_t=float argument and float32 per-component operation boundaries.
   const Vector2 p=a.lerp(b,real_t(double(step)/double(steps)));pp[step]=p;
   Result r=evaluate(p,from_id);
   if(r.code!=OK && from!=to)r=evaluate(p,to_id);
   ep[step]=r.code;
   if(r.code==OK)hp[step]=Vector3(p.x,real_t(r.height),p.y);
  }
  Dictionary d;d["error"]=OK;d["points"]=points;d["positions"]=positions;d["errors"]=errors;return d;
 }
 // Tri-state result: 0/1 exact travel decision, -1 caller must use reference.
 int64_t travel_fused(Vector2 a,Vector2 b,int64_t steps,const String &from,const String &to,double radius,double height,const Dictionary &gates,const Ref<HF08ObstacleKernel> &obstacles) const {
  if(!configured || obstacles.is_null() || !a.is_finite() || !b.is_finite() || steps<1 || steps>65536 || std::abs(a.x)>2147480000. || std::abs(a.y)>2147480000. || std::abs(b.x)>2147480000. || std::abs(b.y)>2147480000.){++fused_fallback;return -1;}
  ++fused_calls;fused_planned+=uint64_t(steps+1);
  const int from_id=find_surface(from),to_id=find_surface(to);Vector3 previous;bool have_previous=false;
  for(int64_t step=0;step<=steps;++step){
   ++fused_visited;const Vector2 p=a.lerp(b,real_t(double(step)/double(steps)));
   Result r=evaluate(p,from_id);if(r.code!=OK && from!=to)r=evaluate(p,to_id);
   if(r.code!=OK){++fused_support_reject;return 0;}
   const Vector3 foot(p.x,real_t(r.height),p.y);++fused_body;
   const auto body=obstacles->evaluate_body(foot,radius,height,gates,false);
   if(body.code==ERR_UNAVAILABLE){++fused_fallback;return -1;}
   if(body.blocked){++fused_body_reject;return 0;}
   if(have_previous){
    ++fused_slope;
    // Scalar coordinate properties/subtraction are double in GDScript;
    // Vector2 construction rounds each difference, length is float32, then
    // the slope threshold returns to double. Do not use Vector3 subtraction.
    const Vector2 horizontal(real_t(double(foot.x)-double(previous.x)),real_t(double(foot.z)-double(previous.z)));
    const double run=double(horizontal.length());
    if(std::abs(double(foot.y)-double(previous.y))>.1+run*.85){++fused_slope_reject;return 0;}
   }
   previous=foot;have_previous=true;
  }
  return 1;
 }
 void reset_profile() {evaluations=0;batch_calls=0;batch_samples=0;fused_calls=0;fused_planned=0;fused_visited=0;fused_body=0;fused_slope=0;fused_support_reject=0;fused_body_reject=0;fused_slope_reject=0;fused_fallback=0;}

 Dictionary statistics() const {Dictionary d;d["evaluations"]=int64_t(evaluations);d["batch_calls"]=int64_t(batch_calls);d["batch_samples"]=int64_t(batch_samples);d["fused_calls"]=int64_t(fused_calls);d["fused_planned_samples"]=int64_t(fused_planned);d["fused_visited_samples"]=int64_t(fused_visited);d["fused_body_checks"]=int64_t(fused_body);d["fused_slope_checks"]=int64_t(fused_slope);d["fused_support_rejections"]=int64_t(fused_support_reject);d["fused_body_rejections"]=int64_t(fused_body_reject);d["fused_slope_rejections"]=int64_t(fused_slope_reject);d["fused_fallbacks"]=int64_t(fused_fallback);return d;}

};
static void initialize(ModuleInitializationLevel level) {if(level==MODULE_INITIALIZATION_LEVEL_SCENE){GDREGISTER_CLASS(HF08ObstacleKernel);GDREGISTER_CLASS(HF08SupportKernel);}}
static void terminate(ModuleInitializationLevel) {}
extern "C" GDExtensionBool GDE_EXPORT hf08_query_init(GDExtensionInterfaceGetProcAddress proc,GDExtensionClassLibraryPtr library,GDExtensionInitialization *init) {
 GDExtensionBinding::InitObject object(proc,library,init);object.register_initializer(initialize);object.register_terminator(terminate);object.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);return object.init();
}

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <cmath>
#include <cstdint>
#include <unordered_map>
#include <vector>
using namespace godot;

// Experimental immutable exact kernel. The original validated Godot geometry
// and ordered cell slots remain the configuration authority.
class HF08SupportKernel : public RefCounted {
 GDCLASS(HF08SupportKernel, RefCounted)
 struct Triangle { Vector2 a,b,c; Vector3 heights; double denominator; int surface; };
 std::vector<Triangle> triangles;
 std::vector<String> surfaces;
 std::unordered_map<uint64_t,std::vector<int>> cells;
 bool configured=false;
 static uint64_t cell_key(int32_t x,int32_t y) { return (uint64_t(uint32_t(x))<<32)|uint32_t(y); }
 static Dictionary error(int code,const char *reason=nullptr) {
  Dictionary d;d["error"]=code;if(reason)d["reason"]=String(reason);return d;
 }
 static double minimum(double a,double b) { return a<b?a:b; }
protected:
 static void _bind_methods() {
  ClassDB::bind_method(D_METHOD("configure","triangles","cells"),&HF08SupportKernel::configure);
  ClassDB::bind_method(D_METHOD("support","point","surface_id"),&HF08SupportKernel::support);
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
  if(!configured || !p.is_finite())return error(ERR_INVALID_PARAMETER);
  // Wrapper falls back for values outside int32 cell range. No float-key rounding.
  int wanted=-1;
  if(!surface_id.is_empty()) {
   for(size_t i=0;i<surfaces.size();++i)if(surfaces[i]==surface_id){wanted=int(i);break;}
   if(wanted<0)return error(ERR_DOES_NOT_EXIST,"NO_TAGGED_SUPPORT");
  }
  const auto found=cells.find(cell_key(int32_t(std::floor(double(p.x))),int32_t(std::floor(double(p.y)))));
  if(found==cells.end())return error(ERR_DOES_NOT_EXIST,"NO_TAGGED_SUPPORT");
  // Ordered pairs mirror Dictionary insertion order, including same-surface updates.
  std::vector<std::pair<int,double>> hits;hits.reserve(2);
  for(int slot:found->second) {
   const Triangle &t=triangles[slot];if(wanted>=0 && t.surface!=wanted)continue;
   // Vector subtraction and cross round at the same float32 boundaries as Godot;
   // division and all following scalar operations are GDScript float64.
   const double u=double((t.b-p).cross(t.c-p))/t.denominator;
   const double v=double((t.c-p).cross(t.a-p))/t.denominator;
   const double w=1.0-u-v;
   if(minimum(u,minimum(v,w))<-.00001)continue;
   const double y=double(t.heights.x)*u+double(t.heights.y)*v+double(t.heights.z)*w;
   bool existing=false;
   for(auto &hit:hits)if(hit.first==t.surface) {
    if(std::abs(hit.second-y)>.001)return error(ERR_INVALID_DATA,"MULTIPLE_HEIGHTS_IN_ONE_SURFACE");
    hit.second=y;existing=true;break;
   }
   if(!existing)hits.emplace_back(t.surface,y);
  }
  if(hits.empty())return error(ERR_DOES_NOT_EXIST,"NO_TAGGED_SUPPORT");
  if(hits.size()!=1)for(const auto &hit:hits)if(std::abs(hit.second-hits[0].second)>.001) {
   Dictionary d=error(ERR_INVALID_DATA,"EXPLICIT_SURFACE_REQUIRED");Array ids;
   for(const auto &row:hits)ids.append(surfaces[row.first]);d["surfaces"]=ids;return d;
  }
  Dictionary d;d["error"]=OK;d["surface_id"]=surfaces[hits[0].first];d["position"]=Vector3(p.x,real_t(hits[0].second),p.y);return d;
 }
};
static void initialize(ModuleInitializationLevel level) {if(level==MODULE_INITIALIZATION_LEVEL_SCENE)GDREGISTER_CLASS(HF08SupportKernel);}
static void terminate(ModuleInitializationLevel) {}
extern "C" GDExtensionBool GDE_EXPORT hf08_query_init(GDExtensionInterfaceGetProcAddress proc,GDExtensionClassLibraryPtr library,GDExtensionInitialization *init) {
 GDExtensionBinding::InitObject object(proc,library,init);object.register_initializer(initialize);object.register_terminator(terminate);object.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);return object.init();
}

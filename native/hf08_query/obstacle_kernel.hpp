#include <godot_cpp/classes/geometry2d.hpp>

// Body-clearance loop only. Geometry predicates still execute through the exact
// official engine singleton used by GDScript, not a replacement polygon algorithm.
class HF08ObstacleKernel : public RefCounted {
 GDCLASS(HF08ObstacleKernel,RefCounted)
 struct Solid {String id,gate;PackedVector2Array polygon;double low,high;};
 std::vector<Solid> solids;
 std::vector<int> all_slots;
 std::unordered_map<uint64_t,std::vector<int>> cells;
 Geometry2D *geometry=nullptr;
 bool configured=false;
 mutable uint64_t body_calls=0;
 static uint64_t key(int32_t x,int32_t y){return (uint64_t(uint32_t(x))<<32)|uint32_t(y);}
 static Dictionary result(int code,bool blocked,const String &id=String()){
  Dictionary d;d["error"]=code;d["blocked"]=blocked;if(code==OK && blocked)d["solid_id"]=id;return d;
 }
protected:
 static void _bind_methods(){
  ClassDB::bind_method(D_METHOD("configure","solids","cells"),&HF08ObstacleKernel::configure);
  ClassDB::bind_method(D_METHOD("obstruction","foot","radius","height","open_gates","force_linear"),&HF08ObstacleKernel::obstruction);
  ClassDB::bind_method(D_METHOD("reset_profile"),&HF08ObstacleKernel::reset_profile);
  ClassDB::bind_method(D_METHOD("statistics"),&HF08ObstacleKernel::statistics);
 }
public:
 struct BodyResult{int code;bool blocked;String id;};
 void reset_profile(){body_calls=0;}
 Dictionary statistics() const{Dictionary d;d["body_calls"]=int64_t(body_calls);return d;}
 int configure(const Array &rows,const Dictionary &source_cells){
  if(configured)return ERR_ALREADY_IN_USE;
  solids.clear();all_slots.clear();cells.clear();
  for(int64_t i=0;i<rows.size();++i){
   if(rows[i].get_type()!=Variant::DICTIONARY)return ERR_INVALID_DATA;
   Dictionary row=rows[i];
   for(const char *name:{"id","gate_id","polygon","min_y","max_y"})if(!row.has(name))return ERR_INVALID_DATA;
   if(Variant(row["id"]).get_type()!=Variant::STRING || Variant(row["gate_id"]).get_type()!=Variant::STRING || Variant(row["polygon"]).get_type()!=Variant::PACKED_VECTOR2_ARRAY)return ERR_INVALID_DATA;
   if(Variant(row["min_y"]).get_type()!=Variant::FLOAT || Variant(row["max_y"]).get_type()!=Variant::FLOAT)return ERR_INVALID_DATA;
   PackedVector2Array polygon=row["polygon"];double low=row["min_y"],high=row["max_y"];
   if(polygon.size()<3 || !std::isfinite(low) || !std::isfinite(high) || high<=low)return ERR_INVALID_DATA;
   for(int64_t j=0;j<polygon.size();++j)if(!polygon[j].is_finite())return ERR_INVALID_DATA;
   solids.push_back({String(row["id"]),String(row["gate_id"]),polygon,low,high});all_slots.push_back(int(i));
  }
  Array keys=source_cells.keys();
  for(int64_t i=0;i<keys.size();++i){
   if(keys[i].get_type()!=Variant::VECTOR2I)return ERR_INVALID_DATA;
   Vector2i cell=keys[i];if(Variant(source_cells[cell]).get_type()!=Variant::ARRAY)return ERR_INVALID_DATA;
   Array slots=source_cells[cell];auto &out=cells[key(cell.x,cell.y)];out.reserve(slots.size());
   for(int64_t j=0;j<slots.size();++j){
    if(slots[j].get_type()!=Variant::INT)return ERR_INVALID_DATA;
    int64_t slot=slots[j];if(slot<0 || slot>=int64_t(solids.size()))return ERR_INVALID_DATA;out.push_back(int(slot));
   }
  }
  geometry=Geometry2D::get_singleton();if(!geometry)return ERR_UNAVAILABLE;
  configured=true;return OK;
 }
 BodyResult evaluate_body(Vector3 foot,double radius,double height,const Dictionary &open_gates,bool force_linear) const{
  ++body_calls;
  if(!configured || !foot.is_finite() || !std::isfinite(radius) || !std::isfinite(height) || radius<0. || height<=0.)return {ERR_INVALID_PARAMETER,true,{}};
  // Integer overflow and non-Boolean gate semantics stay with the original path.
  if(std::abs(double(foot.x))>2147480000. || std::abs(double(foot.z))>2147480000.)return {ERR_UNAVAILABLE,true,{}};
  const Vector2 p(foot.x,foot.z);const std::vector<int> *candidates=&all_slots;
  if(!force_linear && radius<=2.){
   auto found=cells.find(key(int32_t(std::floor(double(p.x)/4.)),int32_t(std::floor(double(p.y)/4.))));
   if(found==cells.end())return {OK,false,{}};candidates=&found->second;
  }
  for(int slot:*candidates){
   const Solid &solid=solids[slot];
   if(!solid.gate.is_empty()){
    const Variant gate=open_gates.get(solid.gate,false);
    if(gate.get_type()!=Variant::BOOL)return {ERR_UNAVAILABLE,true,{}};
    if(bool(gate))continue;
   }
   // GDScript scalar arithmetic is double; geometry vectors remain float32.
   if(double(foot.y)>=solid.high-.00001 || double(foot.y)+height<=solid.low+.00001)continue;
   if(geometry->is_point_in_polygon(p,solid.polygon))return {OK,true,solid.id};
   for(int64_t i=0;i<solid.polygon.size();++i){
    const Vector2 nearest=geometry->get_closest_point_to_segment(p,solid.polygon[i],solid.polygon[(i+1)%solid.polygon.size()]);
    if(double(p.distance_squared_to(nearest))<=radius*radius)return {OK,true,solid.id};
   }
  }
  return {OK,false,{}};
 }
 Dictionary obstruction(Vector3 foot,double radius,double height,const Dictionary &gates,bool linear) const{
  const auto r=evaluate_body(foot,radius,height,gates,linear);return result(r.code,r.blocked,r.id);
 }
};

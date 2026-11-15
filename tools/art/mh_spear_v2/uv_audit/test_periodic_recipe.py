"""No asset/render: verify proposed8x4 tiling conserves repeat+bilinear samples."""
import numpy as np
rng=np.random.default_rng(61112);source=rng.random((13,17,3));atlas=np.tile(source,(4,8,1))
def sample(image,uv):
 h,w,_=image.shape;x=(uv[0]%1)*w-.5;y=(uv[1]%1)*h-.5;ix=int(np.floor(x));iy=int(np.floor(y));fx=x-ix;fy=y-iy
 return image[iy%h,ix%w]*(1-fx)*(1-fy)+image[iy%h,(ix+1)%w]*fx*(1-fy)+image[(iy+1)%h,ix%w]*(1-fx)*fy+image[(iy+1)%h,(ix+1)%w]*fx*fy
errors=[float(np.max(np.abs(sample(source,uv)-sample(atlas,uv/[8,4])))) for uv in rng.uniform(-80,80,(4096,2))]
assert max(errors)<1e-10
print('PERIODIC_UV_RECIPE_BASE_LEVEL_PASS',max(errors),'4096 samples; NOT mip/GPU/art proof')

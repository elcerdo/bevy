// Partial sum debug material

#import bevy_pbr::forward_io::VertexOutput

@group(2) @binding(0) var data: texture_storage_2d<rg32uint, read>;

// @group(2) @binding(0) var data_texture: texture_2d<u32>;
// @group(2) @binding(1) var pattern_sampler: sampler;
// @group(2) @binding(2) var warp_texture: texture_2d<f32>;
// @group(2) @binding(3) var warp_sampler: sampler;
// @group(2) @binding(4) var<uniform> warp_amount: f32;

const TEXTURE_SIZE: vec2<f32> = vec2(16.0);

@fragment
fn fragment(
    in: VertexOutput,
) -> @location(0) vec4<f32> {
    let ij = in.uv.yx * TEXTURE_SIZE;
    var color = vec4(in.uv - vec2(0.5), 0.0, 1.0);
    // let uv_ = textureSample(warp_texture, warp_sampler, in.uv).xy;
    // color = textureSample(pattern_texture, pattern_sampler, mix(in.uv, uv_, warp_amount));
    return color;
}

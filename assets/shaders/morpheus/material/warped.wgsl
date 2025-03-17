// Warped uvs

#import bevy_pbr::forward_io::VertexOutput

@group(2) @binding(0) var pattern_texture: texture_2d<f32>;
@group(2) @binding(1) var pattern_sampler: sampler;
@group(2) @binding(2) var warp_texture: texture_2d<f32>;
@group(2) @binding(3) var warp_sampler: sampler;
@group(2) @binding(4) var<uniform> warp_amount: f32;

@fragment
fn fragment(
    in: VertexOutput,
) -> @location(0) vec4<f32> {
    var color = vec4(0.0);
    let uv_ = textureSample(warp_texture, warp_sampler, in.uv).xy;
    color = textureSample(pattern_texture, pattern_sampler, uv_);
    return color;
}

// Warped uvs

#import bevy_pbr::forward_io::VertexOutput

@group(2) @binding(2) var voronoi_texture: texture_2d<f32>;
@group(2) @binding(3) var voronoi_sampler: sampler;

@fragment
fn fragment(
    in: VertexOutput,
) -> @location(0) vec4<f32> {
    var color = vec4(0.0);
    color = textureSample(voronoi_texture, voronoi_sampler, in.uv_b);
    return color;
}

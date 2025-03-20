// Partial sum debug material

#import bevy_pbr::forward_io::VertexOutput

@group(2) @binding(0) var data: texture_2d<u32>;
// @group(2) @binding(2) var warp_texture: texture_2d<f32>;
// @group(2) @binding(3) var warp_sampler: sampler;
// @group(2) @binding(4) var<uniform> warp_amount: f32;

const TEXTURE_SIZE: vec2<f32> = vec2(16.0);

@fragment
fn fragment(
    in: VertexOutput,
) -> @location(0) vec4<f32> {
    // let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    let location = vec2<i32>(in.uv.yx * (TEXTURE_SIZE - 1));
    let count: u32 = textureLoad(data, location, 0).x;

    let aa = f32((count / 1) % 10) / 9.0;
    let bb = f32((count / 10) % 10) / 9.0;
    let cc = f32((count / 100) % 10) / 9.0;
    var color = vec4(aa, bb, cc, 1.0);

    return color;
}

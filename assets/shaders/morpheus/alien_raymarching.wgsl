#import "shaders/morpheus/sdf/alien.wgsl"::signed_distance_function

#import bevy_pbr::{
    mesh_functions,
    view_transformations,
}

@group(2) @binding(0) var matcap_texture: texture_2d<f32>;
@group(2) @binding(1) var matcap_sampler: sampler;
@group(2) @binding(2) var<uniform> bbox_center: vec3<f32>;

struct Vertex {
    @builtin(instance_index) instance_index: u32,
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) uv: vec2<f32>,
}

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) world_position: vec3<f32>,
    @location(1) world_normal: vec3<f32>,
    @location(2) uv: vec2<f32>,
}

@vertex
fn vertex(vertex: Vertex) -> VertexOutput {
    var out: VertexOutput;
    var world_from_local = mesh_functions::get_world_from_local(vertex.instance_index);
    out.world_position = mesh_functions::mesh_position_local_to_world(world_from_local, vec4(vertex.position, 1.0)).xyz;
    out.world_normal = mesh_functions::mesh_normal_local_to_world(vertex.normal, vertex.instance_index);
    out.clip_position = view_transformations::position_world_to_clip(out.world_position);
    out.uv = vertex.uv;
    return out;
}

@fragment
fn fragment(
    out: VertexOutput,
) -> @location(0) vec4<f32> {
    let eye_position = view_transformations::position_ndc_to_world(vec3(0.0, 0.0, -1.0));
    let world_direction = normalize(out.world_position - eye_position);

    var pos = out.world_position - bbox_center;
    var dist = signed_distance_function(pos);
    for (var kk=0; kk<64; kk++) {
        if (dist <= 0.0) { break; }
        if (length(pos) > sqrt(3.0)) { break; }
        pos += world_direction * dist;
        dist = signed_distance_function(pos);
    }

    if dist > 1e-3 {
        return vec4(0.0);
    }

    let hh = 1e-3;
    let world_grad = normalize(vec3(
        signed_distance_function(pos + vec3(hh, 0.0, 0.0)) - signed_distance_function(pos - vec3(hh, 0.0, 0.0)), 
        signed_distance_function(pos + vec3(0.0, hh, 0.0)) - signed_distance_function(pos - vec3(0.0, hh, 0.0)), 
        signed_distance_function(pos + vec3(0.0, 0.0, hh)) - signed_distance_function(pos - vec3(0.0, 0.0, hh)), 
    ));
    let view_grad = normalize(view_transformations::direction_world_to_view(world_grad));
    var color = textureSample(matcap_texture, matcap_sampler, (view_grad.xy + 1.0) / 2.0);
    
    return color;
}

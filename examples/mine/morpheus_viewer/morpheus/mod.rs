mod camera;
mod raymarching_material;
mod sdf;

use crate::morpheus::raymarching_material::MorpheusRaymarchingMaterial;
use crate::morpheus::sdf::{Sdf, Slot0, Slot1, Slot2, Slot3};

use bevy::prelude::*;

use bevy::color::palettes::basic::BLUE;
use bevy::color::palettes::basic::GREEN;
use bevy::color::palettes::basic::RED;

use std::f32::consts::PI;

//////////////////////////////////////////////////////////////////////

const RAYMARCHING_SOURCE: &str = r#"
#import "SDF_PATH"::signed_distance_function

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

"#;

//////////////////////////////////////////////////////////////////////

pub struct MorpheusPlugin;

impl Plugin for MorpheusPlugin {
    fn build(&self, app: &mut App) {
        info!("** build_morpheus_plugin **");

        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot0>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot1>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot2>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot3>>::default());
        app.add_systems(PreStartup, prepare_shaders);

        app.add_systems(Startup, camera::populate_camera_and_lights);
        app.add_systems(Update, camera::animate_camera);

        app.add_systems(Startup, populate_models);
    }
}

//////////////////////////////////////////////////////////////////////

fn prepare_shader(
    shaders: &mut ResMut<Assets<Shader>>,
    server_asset: &Res<AssetServer>,
    shape: &str,
    ray_handle: Handle<Shader>,
) {
    let sdf_path = format!("shaders/morpheus/sdf/{shape}.wgsl");
    let sdf_handle: Handle<Shader> = server_asset.load::<Shader>(sdf_path.clone());

    let ray_path = format!("shaders/morpheus/raymarching/{shape}.wgsl");
    let mut ray_source: String = RAYMARCHING_SOURCE.into();
    ray_source = ray_source.replace("SDF_PATH", &sdf_path);
    let mut ray_shader = Shader::from_wgsl(ray_source, ray_path);
    ray_shader.file_dependencies.push(sdf_handle);

    shaders.insert(ray_handle.id(), ray_shader);
}

fn prepare_shaders(mut shaders: ResMut<Assets<Shader>>, server_asset: Res<AssetServer>) {
    // let path = path.replace(std::path::MAIN_SEPARATOR, "/");
    // let mut bytes = Vec::new();
    // reader.read_to_end(&mut bytes).await?;

    prepare_shader(&mut shaders, &server_asset, "sphere", Slot0::RAY_HANDLE);
    prepare_shader(&mut shaders, &server_asset, "union", Slot1::RAY_HANDLE);
    prepare_shader(&mut shaders, &server_asset, "alien", Slot2::RAY_HANDLE);
    prepare_shader(&mut shaders, &server_asset, "can", Slot3::RAY_HANDLE);
}

fn populate_models(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut morpheus_slot0_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot0>>>,
    mut morpheus_slot1_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot1>>>,
    mut morpheus_slot2_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot2>>>,
    mut morpheus_slot3_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot3>>>,
    mut standard_materials: ResMut<Assets<StandardMaterial>>,
    asset_server: Res<AssetServer>,
) {
    // axis
    let tube = meshes.add(Mesh::from(Cylinder::new(0.1, 2.0)));
    commands.spawn((
        Mesh3d(tube.clone()),
        MeshMaterial3d(standard_materials.add(StandardMaterial {
            base_color: Color::from(RED),
            ..default()
        })),
        Transform::from_xyz(0.0, -1.2, -1.2)
            .with_rotation(Quat::from_axis_angle(Vec3::Z, PI / 2.0)),
    ));
    commands.spawn((
        Mesh3d(tube.clone()),
        MeshMaterial3d(standard_materials.add(StandardMaterial {
            base_color: Color::from(GREEN),
            ..default()
        })),
        Transform::from_xyz(-1.2, 0.0, -1.2),
    ));
    commands.spawn((
        Mesh3d(tube),
        MeshMaterial3d(standard_materials.add(StandardMaterial {
            base_color: Color::from(BLUE),
            ..default()
        })),
        Transform::from_xyz(-1.2, -1.2, 0.0)
            .with_rotation(Quat::from_axis_angle(Vec3::X, PI / 2.0)),
    ));

    // resources
    let matcap_texture: Handle<Image> =
        asset_server.load("textures/matcap/583629_2E1810_765648_3C1C14-512px.png");
    let cube_mesh: Handle<Mesh> = meshes.add(Mesh::from(Cuboid::new(2.0, 2.0, 2.0)));

    let slot0_center = Vec3::ZERO;
    let slot1_center = Vec3::new(2.0, 0.0, 0.0);
    let slot2_center = Vec3::new(0.0, 2.0, 0.0);
    let slot3_center = Vec3::new(0.0, 0.0, 2.0);

    // materials
    let slot0_material = morpheus_slot0_materials.add(MorpheusRaymarchingMaterial::<Slot0>::new(
        slot0_center,
        matcap_texture.clone(),
    ));
    let slot1_material = morpheus_slot1_materials.add(MorpheusRaymarchingMaterial::<Slot1>::new(
        slot1_center,
        matcap_texture.clone(),
    ));
    let slot2_material = morpheus_slot2_materials.add(MorpheusRaymarchingMaterial::<Slot2>::new(
        slot2_center,
        matcap_texture.clone(),
    ));
    let slot3_material = morpheus_slot3_materials.add(MorpheusRaymarchingMaterial::<Slot3>::new(
        slot3_center,
        matcap_texture.clone(),
    ));

    // models
    commands.spawn((
        Mesh3d(cube_mesh.clone()),
        MeshMaterial3d(slot0_material),
        Transform::from_translation(slot0_center),
    ));
    commands.spawn((
        Mesh3d(cube_mesh.clone()),
        MeshMaterial3d(slot1_material),
        Transform::from_translation(slot1_center),
    ));
    commands.spawn((
        Mesh3d(cube_mesh.clone()),
        MeshMaterial3d(slot2_material),
        Transform::from_translation(slot2_center),
    ));
    commands.spawn((
        Mesh3d(cube_mesh.clone()),
        MeshMaterial3d(slot3_material),
        Transform::from_translation(slot3_center),
    ));
}

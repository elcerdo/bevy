use std::marker::PhantomData;

use bevy::asset::weak_handle;
use bevy::input::mouse::AccumulatedMouseMotion;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};

use bevy::prelude::*;

use bevy::color::palettes::basic::BLUE;
use bevy::color::palettes::basic::GREEN;
use bevy::color::palettes::basic::RED;
use std::f32::consts::PI;

//////////////////////////////////////////////////////////////////////

trait Sdf: TypePath + Clone + Sync + Send {
    fn raymarching_shader() -> ShaderRef;
}

#[derive(Clone, TypePath)]
struct SphereSdf;

const SPHERE_RAY_HANDLE: Handle<Shader> = weak_handle!("1347c9b7-c46a-0000-abcd-023a354b7cac");

impl Sdf for SphereSdf {
    fn raymarching_shader() -> ShaderRef {
        SPHERE_RAY_HANDLE.into()
    }
}

#[derive(Clone, TypePath)]
struct UnionSdf;

const UNION_RAY_HANDLE: Handle<Shader> = weak_handle!("1347c9b7-c46a-1111-abcd-023a354b7cac");

impl Sdf for UnionSdf {
    fn raymarching_shader() -> ShaderRef {
        UNION_RAY_HANDLE.into()
    }
}

#[derive(Clone, TypePath)]
struct AlienSdf;

const ALIEN_RAY_HANDLE: Handle<Shader> = weak_handle!("1347c9b7-c46a-2222-abcd-023a354b7cac");

impl Sdf for AlienSdf {
    fn raymarching_shader() -> ShaderRef {
        ALIEN_RAY_HANDLE.into()
    }
}

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

        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<SphereSdf>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<UnionSdf>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<AlienSdf>>::default());
        app.add_systems(PreStartup, prepare_shaders);

        app.add_systems(Startup, populate_camera_and_lights);
        app.add_systems(Startup, populate_models);
        app.add_systems(Update, animate_camera);
    }
}

fn prepare_shaders(mut shaders: ResMut<Assets<Shader>>, server_asset: Res<AssetServer>) {
    let mut make_raymarching_shader_from_sdf = |shape: &str, ray_handle: Handle<Shader>| {
        let sdf_path = format!("shaders/morpheus/sdf/{shape}.wgsl");
        let sdf_handle: Handle<Shader> = server_asset.load::<Shader>(sdf_path.clone());

        let ray_path = format!("shaders/morpheus/raymarching/{shape}.wgsl");
        let mut ray_source: String = RAYMARCHING_SOURCE.into();
        ray_source = ray_source.replace("SDF_PATH", &sdf_path);
        let mut ray_shader = Shader::from_wgsl(ray_source, ray_path);
        ray_shader.file_dependencies.push(sdf_handle);

        shaders.insert(ray_handle.id(), ray_shader);
    };

    make_raymarching_shader_from_sdf("sphere", SPHERE_RAY_HANDLE);
    make_raymarching_shader_from_sdf("union", UNION_RAY_HANDLE);
    make_raymarching_shader_from_sdf("alien", ALIEN_RAY_HANDLE);
}

//////////////////////////////////////////////////////////////////////

fn populate_models(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut morpheus_sphere_materials: ResMut<Assets<MorpheusRaymarchingMaterial<SphereSdf>>>,
    mut morpheus_union_materials: ResMut<Assets<MorpheusRaymarchingMaterial<UnionSdf>>>,
    mut morpheus_alien_materials: ResMut<Assets<MorpheusRaymarchingMaterial<AlienSdf>>>,
    mut standard_materials: ResMut<Assets<StandardMaterial>>,
    asset_server: Res<AssetServer>,
) {
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

    let matcap_texture = asset_server.load("textures/matcap/583629_2E1810_765648_3C1C14-512px.png");

    let sphere_center = Vec3::new(2.0, 0.0, 0.0);
    let sphere_material = morpheus_sphere_materials.add(
        MorpheusRaymarchingMaterial::<SphereSdf>::new(sphere_center, matcap_texture.clone()),
    );
    commands.spawn((
        Mesh3d(meshes.add(Mesh::from(Cuboid::new(2.0, 2.0, 2.0)))),
        MeshMaterial3d(sphere_material),
        Transform::from_translation(sphere_center),
    ));

    let union_center = Vec3::new(0.0, 0.0, 2.0);
    let union_material = morpheus_union_materials.add(
        MorpheusRaymarchingMaterial::<UnionSdf>::new(union_center, matcap_texture.clone()),
    );
    commands.spawn((
        Mesh3d(meshes.add(Mesh::from(Cuboid::new(2.0, 2.0, 2.0)))),
        MeshMaterial3d(union_material),
        Transform::from_translation(union_center),
    ));

    let alien_center = Vec3::ZERO;
    let alien_material = morpheus_alien_materials.add(
        MorpheusRaymarchingMaterial::<AlienSdf>::new(alien_center, matcap_texture.clone()),
    );
    commands.spawn((
        Mesh3d(meshes.add(Mesh::from(Cuboid::new(2.0, 2.0, 2.0)))),
        MeshMaterial3d(alien_material),
        Transform::from_translation(alien_center),
    ));
}

#[derive(Component)]
struct CameraPivot {
    sensitivity: f32,
}

impl CameraPivot {
    fn default() -> Self {
        Self { sensitivity: 200.0 }
    }
}

fn populate_camera_and_lights(mut commands: Commands) {
    // use bevy::render::camera::ScalingMode;

    info!("** populate_camera_and_lights **");

    // lights
    commands.spawn((
        PointLight {
            shadows_enabled: true,
            intensity: 5.0e6,
            range: 100.0,
            shadow_depth_bias: 0.2,
            ..default()
        },
        Transform::from_xyz(-4.0, 16.0, 8.0),
    ));
    commands.spawn((
        DirectionalLight {
            color: Color::WHITE,
            shadows_enabled: true,
            illuminance: light_consts::lux::OVERCAST_DAY,
            ..default()
        },
        Transform::from_translation(Vec3::Y).looking_at(Vec3::ZERO, Vec3::Y),
    ));

    // camera
    commands
        .spawn((
            Transform::from_translation(Vec3::ZERO),
            CameraPivot::default(),
            InheritedVisibility::VISIBLE,
        ))
        .with_child((
            Transform::from_xyz(0.0, 2.0, -5.0).looking_at(Vec3::new(0., 0., 0.), Vec3::Y),
            Camera3d::default(),
        ));
}

fn animate_camera(
    mut query: Query<(&mut Transform, &CameraPivot)>,
    mouse_input: Res<ButtonInput<MouseButton>>,
    keyboard_input: Res<ButtonInput<KeyCode>>,
    mouse_motion: Res<AccumulatedMouseMotion>,
) {
    let Ok((mut transform, pivot)) = query.single_mut() else {
        return;
    };
    if mouse_input.pressed(MouseButton::Left) {
        let delta = mouse_motion.delta;
        transform.rotation *=
            Quat::from_axis_angle(Vec3::X, PI / 2.0 * delta.y / pivot.sensitivity);
        transform.rotation *=
            Quat::from_axis_angle(Vec3::Y, -PI / 2.0 * delta.x / pivot.sensitivity);
    }
    if keyboard_input.just_pressed(KeyCode::KeyR) {
        transform.rotation = Quat::IDENTITY;
    }
}

//////////////////////////////////////////////////////////////////////

#[derive(Asset, TypePath, AsBindGroup, Clone)]
struct MorpheusRaymarchingMaterial<T: Sdf> {
    #[texture(0)]
    #[sampler(1)]
    matcap_texture: Option<Handle<Image>>,
    #[uniform(2)]
    bbox_center: Vec3,
    phantom: PhantomData<T>,
}

impl<T: Sdf> Material for MorpheusRaymarchingMaterial<T> {
    fn vertex_shader() -> ShaderRef {
        T::raymarching_shader()
    }

    fn fragment_shader() -> ShaderRef {
        T::raymarching_shader()
    }

    fn alpha_mode(&self) -> AlphaMode {
        AlphaMode::Blend
    }
}

impl<T: Sdf> MorpheusRaymarchingMaterial<T> {
    fn new(center: Vec3, matcap_texture: Handle<Image>) -> Self {
        Self {
            bbox_center: center,
            matcap_texture: Some(matcap_texture),
            phantom: PhantomData,
        }
    }
}

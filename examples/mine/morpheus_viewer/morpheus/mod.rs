use crate::slot::{Slot, Slot0, Slot1, Slot2, Slot3, Slot4, Slot5, Slot6, Slot7, ADVECTION_HANDLE};
use crate::snippet::{Snippet, SnippetAssetLoader};

mod camera;
mod raymarching_material;

use raymarching_material::MorpheusRaymarchingMaterial;

use bevy::prelude::*;

use bevy::color::palettes::basic::BLUE;
use bevy::color::palettes::basic::GREEN;
use bevy::color::palettes::basic::RED;

use std::f32::consts::PI;

//////////////////////////////////////////////////////////////////////

pub struct MorpheusPlugin;

impl Plugin for MorpheusPlugin {
    fn build(&self, app: &mut App) {
        info!("** build_morpheus_plugin **");

        app.init_resource::<SnippetHandles>();
        app.init_asset::<Snippet>();
        app.init_asset_loader::<SnippetAssetLoader>();

        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot0>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot1>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot2>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot3>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot4>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot5>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot6>>::default());
        app.add_plugins(MaterialPlugin::<MorpheusRaymarchingMaterial<Slot7>>::default());
        app.add_systems(Update, update_bbox_centers_slot::<Slot0>);
        app.add_systems(Update, update_bbox_centers_slot::<Slot1>);
        app.add_systems(Update, update_bbox_centers_slot::<Slot2>);
        app.add_systems(Update, update_bbox_centers_slot::<Slot3>);
        app.add_systems(Update, update_bbox_centers_slot::<Slot4>);
        app.add_systems(Update, update_bbox_centers_slot::<Slot5>);
        app.add_systems(Update, update_bbox_centers_slot::<Slot6>);
        app.add_systems(Update, update_bbox_centers_slot::<Slot7>);
        app.add_systems(Update, update_internal_state);

        app.add_systems(Startup, camera::populate_camera_and_lights);
        app.add_systems(Update, camera::rotate_camera);
        app.add_systems(Update, camera::zoom_camera);

        // app.add_systems(Startup, populate_models);
        app.add_systems(Startup, populate_advection_model);
    }
}

//////////////////////////////////////////////////////////////////////

#[derive(Default, PartialEq)]
enum State {
    #[default]
    Init,
    LoadingSnippets,
    PreparingShaders,
    Done,
}

#[derive(Resource, Default)]
struct SnippetHandles {
    raymarching_snippet: Handle<Snippet>,
    advection_snippet: Handle<Snippet>,
    state: State,
}

fn make_raymarching_shader_from_snippet(
    server_asset: &Res<AssetServer>,
    ray_snippet: &str,
    shape: &str,
) -> Shader {
    let sdf_path = format!("shaders/morpheus/sdf/{shape}.wgsl");
    let sdf_handle: Handle<Shader> = server_asset.load(sdf_path.clone());

    let ray_path = format!("shaders/morpheus/raymarching/{shape}.wgsl");
    let mut ray_source: String = ray_snippet.to_owned();
    ray_source = ray_source.replace("SDF_PATH", &sdf_path);
    let mut ray_shader = Shader::from_wgsl(ray_source, ray_path);
    ray_shader.file_dependencies.push(sdf_handle);

    ray_shader
}

fn make_advection_shader_from_snippet(
    server_asset: &Res<AssetServer>,
    adv_snippet: &str,
    shape: &str,
) -> Shader {
    let sdf_path = format!("shaders/morpheus/sdf/{shape}.wgsl");
    let sdf_handle: Handle<Shader> = server_asset.load(sdf_path.clone());

    let adv_path = format!("shaders/morpheus/advection/{shape}.wgsl");
    let mut adv_source: String = adv_snippet.to_owned();
    adv_source = adv_source.replace("SDF_PATH", &sdf_path);
    let mut adv_shader = Shader::from_wgsl(adv_source, adv_path);
    adv_shader.file_dependencies.push(sdf_handle);

    adv_shader
}

fn update_internal_state(
    mut handles: ResMut<SnippetHandles>,
    mut shaders: ResMut<Assets<Shader>>,
    snippets: Res<Assets<Snippet>>,
    server_asset: Res<AssetServer>,
) {
    handles.state = match handles.state {
        State::Init => {
            handles.raymarching_snippet =
                server_asset.load::<Snippet>("shaders/morpheus/snippet/raymarching.snippet");
            handles.advection_snippet =
                server_asset.load::<Snippet>("shaders/morpheus/snippet/advection.snippet");
            State::LoadingSnippets
        }
        State::LoadingSnippets => {
            let mut has_snippets: bool = true;
            has_snippets &= snippets.get(handles.raymarching_snippet.id()).is_some();
            has_snippets &= snippets.get(handles.advection_snippet.id()).is_some();
            match has_snippets {
                true => State::PreparingShaders,
                false => State::LoadingSnippets,
            }
        }
        State::PreparingShaders => {
            {
                info!("** prepare_raymarching_shaders **");
                let snippet = snippets.get(handles.raymarching_snippet.id()).unwrap();
                let snippet = &snippet.content;
                shaders.insert(
                    Slot0::RAYMARCHING_HANDLE.id(),
                    make_raymarching_shader_from_snippet(&server_asset, snippet, "icescream"),
                );
                shaders.insert(
                    Slot1::RAYMARCHING_HANDLE.id(),
                    make_raymarching_shader_from_snippet(&server_asset, snippet, "union"),
                );
                shaders.insert(
                    Slot2::RAYMARCHING_HANDLE.id(),
                    make_raymarching_shader_from_snippet(&server_asset, snippet, "alien"),
                );
                shaders.insert(
                    Slot3::RAYMARCHING_HANDLE.id(),
                    make_raymarching_shader_from_snippet(&server_asset, snippet, "can"),
                );
                shaders.insert(
                    Slot4::RAYMARCHING_HANDLE.id(),
                    make_raymarching_shader_from_snippet(&server_asset, snippet, "runman"),
                );
                shaders.insert(
                    Slot5::RAYMARCHING_HANDLE.id(),
                    make_raymarching_shader_from_snippet(&server_asset, snippet, "seascape"),
                );
                shaders.insert(
                    Slot6::RAYMARCHING_HANDLE.id(),
                    make_raymarching_shader_from_snippet(&server_asset, snippet, "cheese"),
                );
                shaders.insert(
                    Slot7::RAYMARCHING_HANDLE.id(),
                    make_raymarching_shader_from_snippet(&server_asset, snippet, "sphere"),
                );
            }
            {
                info!("** prepare_advection_shader **");
                let snippet = snippets.get(handles.advection_snippet.id()).unwrap();
                let snippet = &snippet.content;
                shaders.insert(
                    ADVECTION_HANDLE.id(),
                    make_advection_shader_from_snippet(&server_asset, snippet, "alien"),
                );
            }
            State::Done
        }
        State::Done => State::Done,
    };
}

fn populate_advection_model(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot2>>>,
    asset_server: Res<AssetServer>,
) {
    let matcap_texture: Handle<Image> =
        asset_server.load("textures/matcap/583629_2E1810_765648_3C1C14-512px.png");
    let cube_mesh: Handle<Mesh> = meshes.add(Mesh::from(Cuboid::new(2.0, 2.0, 2.0)));
    let material = materials.add(MorpheusRaymarchingMaterial::<Slot2>::new(
        matcap_texture.clone(),
        1.0,
    ));
    commands.spawn((
        Mesh3d(cube_mesh),
        MeshMaterial3d(material),
        Transform::from_xyz(-1.0, 0.0, 1.0),
    ));
}

fn _populate_models(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut morpheus_slot0_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot0>>>,
    mut morpheus_slot1_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot1>>>,
    mut morpheus_slot2_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot2>>>,
    mut morpheus_slot3_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot3>>>,
    mut morpheus_slot4_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot4>>>,
    mut morpheus_slot5_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot5>>>,
    mut morpheus_slot6_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot6>>>,
    mut morpheus_slot7_materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot7>>>,
    mut standard_materials: ResMut<Assets<StandardMaterial>>,
    asset_server: Res<AssetServer>,
) {
    // textures
    let matcap_texture: Handle<Image> =
        asset_server.load("textures/matcap/583629_2E1810_765648_3C1C14-512px.png");
    let matcap_texture_: Handle<Image> =
        asset_server.load("textures/matcap/392307_B3AE7D_6D5618_847C42-512px.png");

    // meshes
    let tube_mesh = meshes.add(Mesh::from(Cylinder::new(0.05, 2.0)));
    let cube_mesh: Handle<Mesh> = meshes.add(Mesh::from(Cuboid::new(2.0, 2.0, 2.0)));

    // materials
    let slot0_material = morpheus_slot0_materials.add(MorpheusRaymarchingMaterial::<Slot0>::new(
        matcap_texture.clone(),
        1.0,
    ));
    let slot1_material = morpheus_slot1_materials.add(MorpheusRaymarchingMaterial::<Slot1>::new(
        matcap_texture.clone(),
        1.0,
    ));
    let slot2_material = morpheus_slot2_materials.add(MorpheusRaymarchingMaterial::<Slot2>::new(
        matcap_texture.clone(),
        1.0,
    ));
    let slot3_material = morpheus_slot3_materials.add(MorpheusRaymarchingMaterial::<Slot3>::new(
        matcap_texture.clone(),
        1.0,
    ));
    let slot4_material = morpheus_slot4_materials.add(MorpheusRaymarchingMaterial::<Slot4>::new(
        matcap_texture.clone(),
        1.0,
    ));
    let slot5_material = morpheus_slot5_materials.add(MorpheusRaymarchingMaterial::<Slot5>::new(
        matcap_texture.clone(),
        45e-2,
    ));
    let slot6_material = morpheus_slot6_materials.add(MorpheusRaymarchingMaterial::<Slot6>::new(
        matcap_texture.clone(),
        1.0,
    ));
    let slot7_material = morpheus_slot7_materials.add(MorpheusRaymarchingMaterial::<Slot7>::new(
        matcap_texture.clone(),
        1.0,
    ));

    let slot2_material_ = morpheus_slot2_materials.add(MorpheusRaymarchingMaterial::<Slot2>::new(
        matcap_texture_.clone(),
        1.0,
    ));

    commands
        .spawn((
            InheritedVisibility::VISIBLE,
            Transform::from_translation(Vec3::ONE),
        ))
        .with_children(|parent| {
            // axis
            parent.spawn((
                Mesh3d(tube_mesh.clone()),
                MeshMaterial3d(standard_materials.add(StandardMaterial {
                    base_color: Color::from(RED),
                    ..default()
                })),
                Transform::from_xyz(0.0, -1.0, -1.0)
                    .with_rotation(Quat::from_axis_angle(Vec3::Z, PI / 2.0)),
            ));
            parent.spawn((
                Mesh3d(tube_mesh.clone()),
                MeshMaterial3d(standard_materials.add(StandardMaterial {
                    base_color: Color::from(GREEN),
                    ..default()
                })),
                Transform::from_xyz(-1.0, 0.0, -1.0),
            ));
            parent.spawn((
                Mesh3d(tube_mesh),
                MeshMaterial3d(standard_materials.add(StandardMaterial {
                    base_color: Color::from(BLUE),
                    ..default()
                })),
                Transform::from_xyz(-1.0, -1.0, 0.0)
                    .with_rotation(Quat::from_axis_angle(Vec3::X, PI / 2.0)),
            ));

            // models
            parent.spawn((
                Mesh3d(cube_mesh.clone()),
                MeshMaterial3d(slot0_material),
                Transform::from_xyz(-4.0, 0.0, 0.0),
            ));
            parent.spawn((
                Mesh3d(cube_mesh.clone()),
                MeshMaterial3d(slot1_material),
                Transform::from_xyz(-2.0, 0.0, 0.0),
            ));
            parent.spawn((
                Mesh3d(cube_mesh.clone()),
                MeshMaterial3d(slot2_material),
                Transform::default(),
            ));
            parent.spawn((
                Mesh3d(cube_mesh.clone()),
                MeshMaterial3d(slot3_material),
                Transform::from_xyz(2.0, 0.0, 0.0),
            ));
            parent.spawn((
                Mesh3d(cube_mesh.clone()),
                MeshMaterial3d(slot4_material),
                Transform::from_xyz(-4.0, 0.0, 2.0),
            ));
            parent.spawn((
                Mesh3d(cube_mesh.clone()),
                MeshMaterial3d(slot5_material),
                Transform::from_xyz(-2.0, 0.0, 2.0),
            ));
            parent.spawn((
                Mesh3d(cube_mesh.clone()),
                MeshMaterial3d(slot6_material),
                Transform::from_xyz(0.0, 0.0, 2.0),
            ));
            parent.spawn((
                Mesh3d(cube_mesh.clone()),
                MeshMaterial3d(slot7_material),
                Transform::from_xyz(2.0, 0.0, 2.0),
            ));

            parent.spawn((
                Mesh3d(cube_mesh.clone()),
                MeshMaterial3d(slot2_material_),
                Transform::from_xyz(0.0, 2.0, 0.0),
            ));
        });
}

fn update_bbox_centers_slot<S: Slot>(
    query: Query<(
        &GlobalTransform,
        &mut MeshMaterial3d<MorpheusRaymarchingMaterial<S>>,
    )>,
    mut materials: ResMut<Assets<MorpheusRaymarchingMaterial<S>>>,
) {
    for (global, material_handle) in query.iter() {
        let transform = global.compute_transform();
        if let Some(material) = materials.get_mut(material_handle) {
            material.bbox_center = transform.translation;
        }
    }
}

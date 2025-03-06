mod camera;
mod raymarching_material;
mod sdf;
mod snippet;

use raymarching_material::MorpheusRaymarchingMaterial;
use sdf::{Sdf, Slot0, Slot1, Slot2, Slot3};
use snippet::{Snippet, SnippetAssetLoader};

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

        app.add_systems(Startup, camera::populate_camera_and_lights);
        app.add_systems(Startup, populate_models);

        app.add_systems(Update, update_internal_state);
        app.add_systems(Update, update_slot0_bbox_centers);
        app.add_systems(Update, update_slot1_bbox_centers);
        app.add_systems(Update, update_slot2_bbox_centers);
        app.add_systems(Update, update_slot3_bbox_centers);
        app.add_systems(Update, camera::animate_camera);
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
    state: State,
}

fn make_shader_from_snippet(
    server_asset: &Res<AssetServer>,
    ray_snippet: &str,
    shape: &str,
) -> Shader {
    let sdf_path = format!("shaders/morpheus/sdf/{shape}.wgsl");
    let sdf_handle: Handle<Shader> = server_asset.load::<Shader>(sdf_path.clone());

    let ray_path = format!("shaders/morpheus/raymarching/{shape}.wgsl");
    let mut ray_source: String = ray_snippet.to_owned();
    ray_source = ray_source.replace("SDF_PATH", &sdf_path);
    let mut ray_shader = Shader::from_wgsl(ray_source, ray_path);
    ray_shader.file_dependencies.push(sdf_handle);

    ray_shader
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
            State::LoadingSnippets
        }
        State::LoadingSnippets => {
            let has_snippet = snippets.get(handles.raymarching_snippet.id()).is_some();
            match has_snippet {
                true => State::PreparingShaders,
                false => State::LoadingSnippets,
            }
        }
        State::PreparingShaders => {
            info!("** prepare_shaders **");
            let snippet = snippets.get(handles.raymarching_snippet.id()).unwrap();
            let snippet = &snippet.content;
            shaders.insert(
                Slot0::RAY_HANDLE.id(),
                make_shader_from_snippet(&server_asset, snippet, "sphere"),
            );
            shaders.insert(
                Slot1::RAY_HANDLE.id(),
                make_shader_from_snippet(&server_asset, snippet, "union"),
            );
            shaders.insert(
                Slot2::RAY_HANDLE.id(),
                make_shader_from_snippet(&server_asset, snippet, "alien"),
            );
            shaders.insert(
                Slot3::RAY_HANDLE.id(),
                make_shader_from_snippet(&server_asset, snippet, "can"),
            );
            State::Done
        }
        State::Done => State::Done,
    };
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

    // materials
    let slot0_material = morpheus_slot0_materials.add(MorpheusRaymarchingMaterial::<Slot0>::new(
        matcap_texture.clone(),
    ));
    let slot1_material = morpheus_slot1_materials.add(MorpheusRaymarchingMaterial::<Slot1>::new(
        matcap_texture.clone(),
    ));
    let slot3_material = morpheus_slot3_materials.add(MorpheusRaymarchingMaterial::<Slot3>::new(
        matcap_texture.clone(),
    ));

    // models
    commands.spawn((
        Mesh3d(cube_mesh.clone()),
        MeshMaterial3d(slot0_material),
        Transform::default(),
    ));
    commands.spawn((
        Mesh3d(cube_mesh.clone()),
        MeshMaterial3d(slot1_material),
        Transform::from_xyz(2.0, 0.0, 0.0),
    ));
    commands.spawn((
        Mesh3d(cube_mesh.clone()),
        MeshMaterial3d(
            morpheus_slot2_materials.add(MorpheusRaymarchingMaterial::<Slot2>::new(
                matcap_texture.clone(),
            )),
        ),
        Transform::from_xyz(0.0, 2.0, 0.0),
    ));
    commands.spawn((
        Mesh3d(cube_mesh.clone()),
        MeshMaterial3d(
            morpheus_slot2_materials.add(MorpheusRaymarchingMaterial::<Slot2>::new(
                matcap_texture.clone(),
            )),
        ),
        Transform::from_xyz(2.0, 2.0, 0.0),
    ));
    commands.spawn((
        Mesh3d(cube_mesh.clone()),
        MeshMaterial3d(slot3_material),
        Transform::from_xyz(0.0, 0.0, 2.0),
    ));
}

fn update_slot0_bbox_centers(
    query: Query<(
        &Transform,
        &mut MeshMaterial3d<MorpheusRaymarchingMaterial<Slot0>>,
    )>,
    mut materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot0>>>,
) {
    for (transform, material_handle) in query.iter() {
        if let Some(material) = materials.get_mut(material_handle) {
            material.bbox_center = transform.translation;
        }
    }
}

fn update_slot1_bbox_centers(
    query: Query<(
        &Transform,
        &mut MeshMaterial3d<MorpheusRaymarchingMaterial<Slot1>>,
    )>,
    mut materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot1>>>,
) {
    for (transform, material_handle) in query.iter() {
        if let Some(material) = materials.get_mut(material_handle) {
            material.bbox_center = transform.translation;
        }
    }
}

fn update_slot2_bbox_centers(
    query: Query<(
        &Transform,
        &mut MeshMaterial3d<MorpheusRaymarchingMaterial<Slot2>>,
    )>,
    mut materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot2>>>,
) {
    for (transform, material_handle) in query.iter() {
        if let Some(material) = materials.get_mut(material_handle) {
            material.bbox_center = transform.translation;
        }
    }
}

fn update_slot3_bbox_centers(
    query: Query<(
        &Transform,
        &mut MeshMaterial3d<MorpheusRaymarchingMaterial<Slot3>>,
    )>,
    mut materials: ResMut<Assets<MorpheusRaymarchingMaterial<Slot3>>>,
) {
    for (transform, material_handle) in query.iter() {
        if let Some(material) = materials.get_mut(material_handle) {
            material.bbox_center = transform.translation;
        }
    }
}

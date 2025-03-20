//! headless wgpu pipeline cli

mod camera;

use bevy::prelude::*;

use bevy::color::palettes::css::YELLOW;

fn main() {
    let mut app = App::new();

    app.add_plugins(DefaultPlugins);
    app.add_plugins(camera::CameraPlugin);

    app.add_systems(Startup, setup);

    app.run();
}

fn setup(
    mut commands: Commands,
    mut materials: ResMut<Assets<StandardMaterial>>,
    mut meshes: ResMut<Assets<Mesh>>,
) {
    warn!("hello world");

    commands.spawn((
        Mesh3d(meshes.add(Plane3d::default())),
        MeshMaterial3d(materials.add(StandardMaterial {
            perceptual_roughness: 0.2,
            metallic: 0.0,
            base_color: YELLOW.into(),
            alpha_mode: AlphaMode::Blend,
            ..default()
        })),
    ));
}

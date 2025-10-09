// use crate::ui::UiGrab;

use bevy::input::mouse::AccumulatedMouseMotion;
use bevy::input::mouse::MouseScrollUnit;
use bevy::input::mouse::MouseWheel;
use bevy::prelude::*;

use std::f32::consts::PI;

#[derive(Component)]
pub struct CameraPivot {
    sensitivity: f32,
}

impl CameraPivot {
    fn default() -> Self {
        Self { sensitivity: 200.0 }
    }
}

pub fn populate_camera_and_lights(mut commands: Commands, asset_server: Res<AssetServer>) {
    info!("** populate_camera_and_lights **");

    // lights
    // commands.spawn((
    //     PointLight {
    //         shadows_enabled: true,
    //         intensity: 5.0e6,
    //         range: 100.0,
    //         shadow_depth_bias: 0.2,
    //         ..default()
    //     },
    //     Transform::from_xyz(-4.0, 16.0, 8.0),
    // ));
    // commands.spawn((
    //     DirectionalLight {
    //         color: Color::WHITE,
    //         shadows_enabled: true,
    //         illuminance: light_consts::lux::OVERCAST_DAY,
    //         ..default()
    //     },
    //     Transform::from_translation(Vec3::Y).looking_at(Vec3::X + Vec3::Z, Vec3::Y),
    // ));

    // camera
    commands
        .spawn((
            Transform::from_translation(Vec3::ZERO),
            CameraPivot::default(),
            InheritedVisibility::VISIBLE,
        ))
        .with_child((
            Transform::from_xyz(0.0, 8.0, 0.0).looking_at(Vec3::new(0., 0., 0.), Vec3::Z),
            Camera3d::default(),
            EnvironmentMapLight {
                diffuse_map: asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
                specular_map: asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
                intensity: 5e2,
                ..default()
            },
        ));
}

pub fn zoom_camera(
    query: Single<&mut Transform, With<Camera3d>>,
    mut evr_scroll: EventReader<MouseWheel>,
) {
    let mut transform = query.into_inner();
    for event in evr_scroll.read() {
        let delta = match event.unit {
            MouseScrollUnit::Line => event.y * 1e-1,
            MouseScrollUnit::Pixel => event.y * 1e-2,
        };
        transform.translation -= Vec3::new(0.0, 3.0, -7.5) * delta;
    }
}

pub fn rotate_camera(
    query: Single<(&mut Transform, &CameraPivot)>,
    mouse_input: Res<ButtonInput<MouseButton>>,
    keyboard_input: Res<ButtonInput<KeyCode>>,
    mouse_motion: Res<AccumulatedMouseMotion>,
    // grab: Res<UiGrab>,
) {
    // if grab.any() {
    //     return;
    // }
    let (mut transform, pivot) = query.into_inner();
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

use bevy::input::mouse::AccumulatedMouseMotion;
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
            Transform::from_xyz(0.0, 3.0, -7.5).looking_at(Vec3::new(0., 0., 0.), Vec3::Y),
            Camera3d::default(),
            EnvironmentMapLight {
                diffuse_map: asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
                specular_map: asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
                intensity: 5e2,
                ..default()
            },
        ));
}

pub fn animate_camera(
    mut query: Query<(&mut Transform, &CameraPivot)>,
    mouse_input: Res<ButtonInput<MouseButton>>,
    keyboard_input: Res<ButtonInput<KeyCode>>,
    mouse_motion: Res<AccumulatedMouseMotion>,
) {
    let Ok((mut transform, pivot)) = query.single_mut() else {
        return;
    };
    if mouse_input.pressed(MouseButton::Right) {
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

//! headless wgpu pipeline cli

mod camera;
mod partial_sum;

use bevy::prelude::*;

fn main() {
    let mut app = App::new();

    app.add_plugins(DefaultPlugins);
    app.add_plugins(camera::CameraPlugin);
    app.add_plugins(partial_sum::PartialSumPlugin);

    app.add_systems(Startup, setup);
    app.add_systems(Update, keyboard_quit_with_escape);
    app.add_systems(Update, keyboard_reinit_with_space);

    app.run();
}

fn setup(
    mut commands: Commands,
    mut materials: ResMut<Assets<StandardMaterial>>,
    mut meshes: ResMut<Assets<Mesh>>,
) {
    warn!("hello world");
}

fn keyboard_quit_with_escape(
    mut writer: EventWriter<AppExit>,
    keyboard: Res<ButtonInput<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::Escape) {
        writer.write(AppExit::Success);
    }
}

fn keyboard_reinit_with_space(
    mut triggers: ResMut<partial_sum::PartialSumTriggers>,
    keyboard: Res<ButtonInput<KeyCode>>,
) {
    let should_reinit = keyboard.pressed(KeyCode::Space);
    triggers.should_reinit = should_reinit;
    if should_reinit {
        warn!("reinit");
    }
}

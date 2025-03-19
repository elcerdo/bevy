//! morpheus model viewer

mod advection;
mod morpheus;
mod ui;

use bevy::prelude::*;

fn main() {
    let mut app = App::new();

    app.insert_resource(bevy::pbr::DirectionalLightShadowMap { size: 2048 });
    app.add_plugins(DefaultPlugins);

    #[cfg(feature = "bevy_dev_tools")]
    {
        // fps overlay
        use bevy::dev_tools::fps_overlay::FpsOverlayConfig;
        use bevy::dev_tools::fps_overlay::FpsOverlayPlugin;
        app.add_plugins(FpsOverlayPlugin {
            config: FpsOverlayConfig::default(),
        });
    }

    #[cfg(feature = "bevy_dev_tools")]
    {
        // wireframe toggle
        use bevy::color::palettes::basic::WHITE;
        use bevy::pbr::wireframe::WireframeConfig;
        use bevy::pbr::wireframe::WireframePlugin;
        app.insert_resource(WireframeConfig {
            global: false,
            default_color: WHITE.into(),
        });
        app.add_plugins(WireframePlugin);
        app.add_systems(
            Update,
            |mut wireframe_config: ResMut<WireframeConfig>, keyboard: Res<ButtonInput<KeyCode>>| {
                if keyboard.just_pressed(KeyCode::Space) {
                    wireframe_config.global = !wireframe_config.global;
                }
            },
        );
    }

    app.add_plugins(morpheus::MorpheusPlugin);
    app.add_plugins(advection::AdvectionPlugin);
    app.add_plugins(ui::UiPlugin);

    app.add_systems(Update, keyboard_quit_with_escape);
    app.add_systems(Update, keyboard_reinit_advection);
    app.add_systems(Update, keyboard_toggle_advection_learning_rate);
    app.add_systems(Update, ui_update_buttons);
    app.add_systems(Update, ui_update_sliders);

    app.run();
}

fn ui_update_buttons(
    query: Query<&ui::ButtonData, Changed<ui::ButtonData>>,
    mut triggers: ResMut<advection::AdvectionTriggers>,
) {
    for data in query {
        match data.index {
            0 => {
                triggers.should_reinit = true;
            }
            _ => {
                warn!("clicked {} {}", data.index, data.count);
            }
        }
    }
}

fn ui_update_sliders(
    query: Query<&ui::SliderData, Changed<ui::SliderData>>,
    mut query_: Query<&mut advection::AdvectionSettings>,
    query__: Query<&MeshMaterial3d<advection::WarpedMaterial>>,
    mut materials: ResMut<Assets<advection::WarpedMaterial>>,
    mut triggers: ResMut<advection::AdvectionTriggers>,
) {
    for data in query {
        match data.index {
            0 => {
                assert!(data.ratio >= 0.0);
                assert!(data.ratio <= 1.0);
                let learning_rate = 3.0 * (data.ratio - 1.0);
                let learning_rate = ops::powf(10.0, learning_rate);
                for mut settings in query_.iter_mut() {
                    settings.learning_rate = learning_rate;
                    debug!("learning_rate {:04.2}", settings.learning_rate);
                }
                triggers.should_reinit = true;
            }
            1 => {
                assert!(data.ratio >= 0.0);
                assert!(data.ratio <= 1.0);
                for material_handle in query__.iter() {
                    let material = materials.get_mut(material_handle).unwrap();
                    material.warp_amount = data.ratio;
                    debug!("warp {:04.2}", material.warp_amount);
                }
            }
            _ => {
                warn!("slided {} {}", data.index, data.ratio);
            }
        }
    }
}

fn keyboard_quit_with_escape(
    mut writer: EventWriter<AppExit>,
    keyboard: Res<ButtonInput<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::Escape) {
        writer.write(AppExit::Success);
    }
}

fn keyboard_reinit_advection(
    mut triggers: ResMut<advection::AdvectionTriggers>,
    keyboard: Res<ButtonInput<KeyCode>>,
) {
    let should_reinit = keyboard.pressed(KeyCode::Space) || keyboard.just_pressed(KeyCode::Tab);
    triggers.should_reinit = should_reinit;
    if should_reinit {
        debug!("reinit");
    }
}

fn keyboard_toggle_advection_learning_rate(
    mut all_settings: Query<&mut advection::AdvectionSettings>,
    keyboard: Res<ButtonInput<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::Tab) {
        for mut settings in all_settings.iter_mut() {
            settings.learning_rate = if settings.learning_rate > 1e-1 {
                1e-2
            } else {
                advection::AdvectionSettings::default().learning_rate
            };
            warn!("learning_rate {:04.2}", settings.learning_rate);
        }
    }
}

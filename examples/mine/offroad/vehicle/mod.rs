mod data;
mod physics;

use data::BoatData;
use data::LapStat;
use data::Player;

use crate::global_state::{GlobalState, TrackNickname, TRACK_NICKNAMES};
use crate::material::racing_line_material;
use crate::track::{Segment, Track, TRACK_HANDLES};

use bevy::asset::{AssetServer, Assets};
use bevy::color::Srgba;
use bevy::math::Vec3Swizzles;
use bevy::pbr::{NotShadowCaster, StandardMaterial};

use bevy::prelude::MeshMaterial3d;
use bevy::prelude::State;
use bevy::prelude::Text;
use bevy::prelude::{info, warn};
use bevy::prelude::{ButtonInput, KeyCode};
use bevy::prelude::{Commands, Component, NextState, Query, Res, ResMut, With};
use bevy::prelude::{Entity, Time, Transform};
// use bevy::prelude::{Gamepad, GamepadAxis, GamepadButton};

const COLOR_P1: Srgba = bevy::color::palettes::css::LIGHT_GRAY;
const COLOR_P2: Srgba = bevy::color::palettes::css::HOT_PINK;
const COLOR_P3: Srgba = bevy::color::palettes::css::LIGHT_GREEN;
const COLOR_BEST_LAP_BOARD: Srgba = bevy::color::palettes::css::WHITE;

const MODEL_SCALE: f32 = 0.15;

const MODEL_P1: &str = "models/offroad/boat_p1.glb";
const MODEL_P2: &str = "models/offroad/boat_p2.glb";
const MODEL_P3: &str = "models/offroad/boat_p3.glb";
const MODEL_CUP: &str = "models/offroad/cup.glb";

const COLOR_FIRST: Srgba = bevy::color::palettes::css::GOLD;
const COLOR_SECOND: Srgba = bevy::color::palettes::css::SILVER;
const COLOR_THIRD: Srgba = bevy::color::palettes::css::ROSY_BROWN;
const COLOR_CUP: Srgba = bevy::color::palettes::css::BLACK;

//////////////////////////////////////////////////////////////////////

pub struct VehiclePlugin;

impl bevy::prelude::Plugin for VehiclePlugin {
    fn build(&self, app: &mut bevy::prelude::App) {
        use bevy::prelude::*;
        for track_nickname in TRACK_NICKNAMES {
            let state = GlobalState::InGame(*track_nickname);
            app.add_systems(OnEnter(state), (populate_boards, populate_vehicles));
            app.add_systems(OnExit(state), depopulate_all);
            app.add_systems(
                Update,
                (
                    reset_vehicle_positions,
                    physics::update_vehicle_physics,
                    resolve_checkpoints,
                    update_boards,
                    exit_game,
                )
                    .chain()
                    .run_if(in_state(state)),
            );
        }
    }
}

#[derive(Component)]
struct StatusMarker;

#[derive(Component)]
struct BoardBestLapMarker;

#[derive(Component)]
struct PriceMarker(usize);

#[derive(Component)]
struct VehicleSceneMarker;

fn populate_boards(mut commands: Commands) {
    use bevy::prelude::*;

    info!("** populate_boards **");

    // best lap board
    commands.spawn((
        Text::new("$$best_lap_leaderboard$$"),
        Node {
            position_type: PositionType::Absolute,
            bottom: Val::Px(5.0),
            right: Val::Px(5.0),
            ..Node::default()
        },
        TextFont {
            font_size: 25.0,
            ..TextFont::default()
        },
        TextLayout::new_with_justify(JustifyText::Right),
        TextColor(COLOR_BEST_LAP_BOARD.into()),
        BoardBestLapMarker,
        VehicleSceneMarker,
    ));

    // ui player status
    let layout = TextLayout::new_with_justify(JustifyText::Right);
    let font = TextFont {
        font_size: 16.0,
        ..TextFont::default()
    };
    commands.spawn((
        Text::new("$$status_p1$$"),
        font.clone(),
        layout,
        Node {
            position_type: PositionType::Absolute,
            top: Val::Px(5.0),
            left: Val::Px(5.0),
            ..Node::default()
        },
        TextColor(COLOR_P1.into()),
        StatusMarker,
        VehicleSceneMarker,
    ));
    commands.spawn((
        Text::new("$$status_p2$$"),
        font.clone(),
        layout,
        Node {
            position_type: PositionType::Absolute,
            top: Val::Px(5.0),
            right: Val::Px(5.0),
            ..Node::default()
        },
        TextColor(COLOR_P2.into()),
        StatusMarker,
        VehicleSceneMarker,
    ));
    commands.spawn((
        Text::new("$$status_p3$"),
        font,
        layout,
        Node {
            position_type: PositionType::Absolute,
            bottom: Val::Px(5.0),
            left: Val::Px(5.0),
            ..Node::default()
        },
        TextColor(COLOR_P3.into()),
        StatusMarker,
        VehicleSceneMarker,
    ));
}

fn depopulate_all(mut commands: Commands, query: Query<Entity, With<VehicleSceneMarker>>) {
    for entity in query {
        commands.entity(entity).despawn();
    }
}

fn populate_vehicles(
    mut commands: Commands,
    mut materials: ResMut<Assets<StandardMaterial>>,
    server: Res<AssetServer>,
    tracks: Res<Assets<Track>>,
    state: Res<State<GlobalState>>,
) {
    use bevy::prelude::*;

    info!("** populate_vehicles **");

    let track = match state.get() {
        GlobalState::InGame(TrackNickname::Beginner) => tracks.get(&TRACK_HANDLES[0]),
        GlobalState::InGame(TrackNickname::Vertical) => tracks.get(&TRACK_HANDLES[1]),
        GlobalState::InGame(TrackNickname::Advanced) => tracks.get(&TRACK_HANDLES[2]),
        _ => unreachable!(),
    }
    .unwrap();

    assert!(track.is_looping);

    // vehicles
    let model_p1: Handle<Scene> = server.load(GltfAssetLabel::Scene(0).from_asset(MODEL_P1));
    let model_p2: Handle<Scene> = server.load(GltfAssetLabel::Scene(0).from_asset(MODEL_P2));
    let model_p3: Handle<Scene> = server.load(GltfAssetLabel::Scene(0).from_asset(MODEL_P3));
    let initial_righthand = track.initial_forward.cross(track.initial_up);
    let pos_p1 = track.initial_position;
    let pos_p2 = track.initial_position + initial_righthand * track.initial_left / 2.0;
    let pos_p3 = track.initial_position + initial_righthand * track.initial_right / 2.0;
    commands.spawn((
        VehicleSceneMarker,
        SceneRoot(model_p1),
        BoatData::from_player_position_and_forward(
            Player::One,
            pos_p1.xz(),
            track.initial_forward.xz(),
        ),
        Transform::from_scale(Vec3::ONE * MODEL_SCALE),
    ));
    commands.spawn((
        VehicleSceneMarker,
        SceneRoot(model_p2),
        BoatData::from_player_position_and_forward(
            Player::Two,
            pos_p2.xz(),
            track.initial_forward.xz(),
        ),
        Transform::from_scale(Vec3::ONE * MODEL_SCALE),
    ));
    commands.spawn((
        VehicleSceneMarker,
        SceneRoot(model_p3),
        BoatData::from_player_position_and_forward(
            Player::Three,
            pos_p3.xz(),
            track.initial_forward.xz(),
        ),
        Transform::from_scale(Vec3::ONE * MODEL_SCALE),
    ));

    // prices
    let model_cup: Handle<Mesh> = server.load(
        GltfAssetLabel::Primitive {
            mesh: 0,
            primitive: 0,
        }
        .from_asset(MODEL_CUP),
    );
    commands.spawn((
        VehicleSceneMarker,
        PriceMarker(0),
        Mesh3d(model_cup.clone()),
        MeshMaterial3d(materials.add(StandardMaterial {
            perceptual_roughness: 0.0,
            metallic: 1.0,
            emissive: COLOR_FIRST.into(),
            base_color: COLOR_CUP.into(),
            ..StandardMaterial::default()
        })),
        NotShadowCaster,
        Transform::from_translation(-10.0 * Vec3::Y)
            * Transform::from_scale(Vec3::ONE * MODEL_SCALE)
            * Transform::from_translation(Vec3::Y * MODEL_SCALE),
    ));

    commands.spawn((
        VehicleSceneMarker,
        PriceMarker(1),
        Mesh3d(model_cup.clone()),
        MeshMaterial3d(materials.add(StandardMaterial {
            perceptual_roughness: 0.0,
            metallic: 1.0,
            emissive: COLOR_SECOND.into(),
            base_color: COLOR_CUP.into(),
            ..StandardMaterial::default()
        })),
        NotShadowCaster,
        Transform::from_translation(-10.0 * Vec3::Y)
            * Transform::from_scale(Vec3::ONE * MODEL_SCALE)
            * Transform::from_translation(Vec3::Y * MODEL_SCALE),
    ));

    commands.spawn((
        VehicleSceneMarker,
        PriceMarker(2),
        Mesh3d(model_cup.clone()),
        MeshMaterial3d(materials.add(StandardMaterial {
            perceptual_roughness: 0.0,
            metallic: 1.0,
            emissive: COLOR_THIRD.into(),
            base_color: COLOR_CUP.into(),
            ..StandardMaterial::default()
        })),
        NotShadowCaster,
        Transform::from_translation(-10.0 * Vec3::Y)
            * Transform::from_scale(Vec3::ONE * MODEL_SCALE)
            * Transform::from_translation(Vec3::Y * MODEL_SCALE),
    ));
}

fn exit_game(mut next_state: ResMut<NextState<GlobalState>>, keyboard: Res<ButtonInput<KeyCode>>) {
    if keyboard.just_pressed(KeyCode::Escape) {
        next_state.set(GlobalState::GameDone);
    }
}

fn reset_vehicle_positions(mut boats: Query<&mut BoatData>, keyboard: Res<ButtonInput<KeyCode>>) {
    if keyboard.just_pressed(KeyCode::KeyR) {
        for mut boat in &mut boats {
            boat.reset();
        }
    }
}

fn update_boards(
    mut materials: ResMut<Assets<racing_line_material::RacingLineMaterial>>,
    material_handles: Query<&MeshMaterial3d<racing_line_material::RacingLineMaterial>>,
    cup_transforms: Query<(&mut Transform, &PriceMarker)>,
    boats: Query<&BoatData>,
    best_lap_labels: Query<&mut Text, With<BoardBestLapMarker>>,
    tracks: Res<Assets<Track>>,
    state: Res<State<GlobalState>>,
) {
    use std::time::Duration;

    let track = match state.get() {
        GlobalState::InGame(TrackNickname::Beginner) => tracks.get(&TRACK_HANDLES[0]),
        GlobalState::InGame(TrackNickname::Vertical) => tracks.get(&TRACK_HANDLES[1]),
        GlobalState::InGame(TrackNickname::Advanced) => tracks.get(&TRACK_HANDLES[2]),
        _ => unreachable!(),
    }
    .unwrap();

    assert!(track.is_looping);

    // sort by best lap
    let mut sorted_lap_duration_boats: Vec<(Duration, &BoatData)> = vec![];
    for boat in boats {
        let Some(best_stat) = &boat.maybe_best_stat else {
            continue;
        };
        let lap_duration = best_stat.lap_duration();
        sorted_lap_duration_boats.push((lap_duration, boat));
    }
    sorted_lap_duration_boats.sort_by_key(|(lap_duration, _)| *lap_duration);

    // update racing line cursors
    if !sorted_lap_duration_boats.is_empty() {
        let best_boat_position = sorted_lap_duration_boats[0].1.position_current;
        for material_handle in material_handles.iter() {
            if let Some(material) = materials.get_mut(material_handle) {
                let mut position = best_boat_position;
                position -= track.initial_position.xz();
                position.x = -position.x;
                material.cursor_position = position;
            }
        }
    }

    // udpate cups
    for (mut cup_transform, PriceMarker(nn)) in cup_transforms {
        let nn = *nn;
        if nn >= sorted_lap_duration_boats.len() {
            continue;
        }
        let position_current = sorted_lap_duration_boats[nn].1.position_current;
        cup_transform.translation.x = position_current.x;
        cup_transform.translation.y = 1.2;
        cup_transform.translation.z = position_current.y;
    }

    // update labels
    const RANK_NAMES: [&str; 3] = ["1st", "2nd", "3rd"];
    assert!(sorted_lap_duration_boats.len() <= RANK_NAMES.len());
    let mut rr = vec![];
    for ((duration, boat), rank_name) in sorted_lap_duration_boats.iter().zip(RANK_NAMES) {
        rr.push(format!(
            "{} {:>6.3} {}",
            boat.player,
            duration.as_secs_f32(),
            rank_name
        ));
    }
    let label = format!("{}\nBEST LAP", rr.join("\n"));
    for mut best_lap_label in best_lap_labels {
        *best_lap_label = label.clone().into();
    }
}

fn resolve_checkpoints(
    mut boats: Query<&mut BoatData>,
    status_labels: Query<&mut Text, With<StatusMarker>>,
    tracks: Res<Assets<Track>>,
    state: Res<State<GlobalState>>,
    time: Res<Time>,
) {
    let track = match state.get() {
        GlobalState::InGame(TrackNickname::Beginner) => tracks.get(&TRACK_HANDLES[0]),
        GlobalState::InGame(TrackNickname::Vertical) => tracks.get(&TRACK_HANDLES[1]),
        GlobalState::InGame(TrackNickname::Advanced) => tracks.get(&TRACK_HANDLES[2]),
        _ => unreachable!(),
    }
    .unwrap();

    assert!(track.is_looping);
    assert!(!track.track_kdtree.is_empty());
    assert!(!track.checkpoint_kdtree.is_empty());
    assert!(boats.iter().len() == status_labels.iter().len());

    // bounce track boundary
    for mut boat in &mut boats {
        let query_segment = Segment::from_endpoints(boat.position_current, boat.position_previous);
        let closest_segment = track.track_kdtree.nearest(&query_segment).unwrap();
        assert!(query_segment.ii == 255);
        assert!(closest_segment.item.ii == 0 || closest_segment.item.ii == 1);
        if closest_segment.item.clips(&query_segment) {
            boat.position_previous = closest_segment.item.mirror(boat.position_previous);
            boat.position_current = closest_segment.item.mirror(boat.position_current);
        }
    }

    // update crossed checkpoints
    let top_now = time.elapsed();
    for mut boat in &mut boats {
        let query_segment = Segment::from_endpoints(boat.position_current, boat.position_previous);
        let closest_segment = track.checkpoint_kdtree.nearest(&query_segment).unwrap();
        assert!(query_segment.ii == 255);
        assert!(closest_segment.item.ii != 255);
        boat.current_stat.update(top_now);
        if closest_segment.item.intersects(&query_segment) {
            if boat
                .current_stat
                .patate(closest_segment.item.ii, track.checkpoint_count, top_now)
            {
                boat.maybe_last_stat = Some(boat.current_stat.clone());
                boat.maybe_best_stat = Some(match &boat.maybe_best_stat {
                    None => boat.current_stat.clone(),
                    Some(best_stat) => {
                        if boat.current_stat.lap_duration() < best_stat.lap_duration() {
                            boat.current_stat.clone()
                        } else {
                            best_stat.clone()
                        }
                    }
                });
                boat.lap_count += 1;
                let is_new_best: bool =
                    boat.maybe_best_stat.clone() == boat.maybe_last_stat.clone();
                warn!(
                    "player {} completed lap {} in {:>6.3}{}",
                    boat.player,
                    boat.lap_count,
                    boat.current_stat.lap_duration().as_secs_f32(),
                    if is_new_best { " NEW BEST LAP !!!" } else { "" },
                );
                boat.current_stat = LapStat::invalid();
            }
        }
    }

    // prepare ui status label
    for (boat, mut status_label) in boats.iter().zip(status_labels) {
        let mut ss: Vec<String> = vec![];
        ss.push(format!(
            "{} lap{}\ncurrent   last   best\n{:>6.3} {:>6.3} {:>6.3}",
            boat.player,
            boat.lap_count,
            match boat.current_stat.is_valid() {
                true => boat.current_stat.lap_duration().as_secs_f32(),
                false => -1.0,
            },
            match &boat.maybe_last_stat {
                None => 0.0,
                Some(stat) => stat.lap_duration().as_secs_f32(),
            },
            match &boat.maybe_best_stat {
                None => 0.0,
                Some(stat) => stat.lap_duration().as_secs_f32(),
            },
        ));

        /*
        for kk in 1..track.checkpoint_count {
            let maybe_checkpoint_top = boat.current_stat.checkpoint_to_tops.get(&kk);
            let aa: String = match maybe_checkpoint_top {
                Some(checkpoint_top) => {
                    let lap_duration =
                        (*checkpoint_top - boat.current_stat.top_start).as_secs_f32();
                    format!("{:>6.3}", lap_duration)
                }
                None => "     _".into(),
            };
            let bb: String = match &boat.maybe_last_stat {
                Some(stat) => {
                    let stat_top = stat.checkpoint_to_tops.get(&kk).unwrap();
                    let stat_duration = (*stat_top - stat.top_start).as_secs_f32();
                    match maybe_checkpoint_top {
                        Some(checkpoint_top) => {
                            let lap_duration =
                                (*checkpoint_top - boat.current_stat.top_start).as_secs_f32();
                            format!("{:>+5.3}", lap_duration - stat_duration)
                        }
                        None => {
                            format!("{:>6.3}", stat_duration)
                        }
                    }
                }
                None => "     _".into(),
            };
            let cc: String = match &boat.maybe_best_stat {
                Some(stat) => {
                    let stat_top = stat.checkpoint_to_tops.get(&kk).unwrap();
                    let stat_duration = (*stat_top - stat.top_start).as_secs_f32();
                    match maybe_checkpoint_top {
                        Some(checkpoint_top) => {
                            let lap_duration =
                                (*checkpoint_top - boat.current_stat.top_start).as_secs_f32();
                            format!("{:>+5.3}", lap_duration - stat_duration)
                        }
                        None => {
                            format!("{:>6.3}", stat_duration)
                        }
                    }
                }
                None => "     _".into(),
            };
            ss.push(format!("#{} {} {} {}", kk, aa, bb, cc));
        }
        */

        *status_label = ss.join("\n").into();
    }
}

use crate::track::{RacingLineMaterial, Segment, Track, TRACK_CURRENT_HANDLE};

use bevy::asset::{AssetServer, Assets};
use bevy::color::Srgba;
use bevy::math::{Mat2, Quat, Vec2, Vec3, Vec3Swizzles};
use bevy::pbr::StandardMaterial;
use bevy::render::mesh::Mesh;

use bevy::prelude::Text;
use bevy::prelude::{info, warn};
use bevy::prelude::{ButtonInput, KeyCode};
use bevy::prelude::{Commands, Component, Handle, Query, Res, ResMut, Time, Transform, With};
use bevy::prelude::{Entity, Gamepad, GamepadAxis, GamepadButton};
use bevy::prelude::{Mesh3d, MeshMaterial3d};

use std::collections::HashMap;
use std::fmt;
use std::time::Duration;

const COLOR_P1: Srgba = bevy::color::palettes::css::LIGHT_GRAY;
const COLOR_P2: Srgba = bevy::color::palettes::css::LIGHT_PINK;
const COLOR_P3: Srgba = bevy::color::palettes::basic::LIME;

use bevy::color::palettes::css::GOLD;
use std::f32::consts::PI;

const MODEL_ASSET_PATH: &str = "models/offroad/boat.glb#Mesh0/Primitive0";

//////////////////////////////////////////////////////////////////////

pub struct VehiclePlugin;

impl bevy::prelude::Plugin for VehiclePlugin {
    fn build(&self, app: &mut bevy::prelude::App) {
        use bevy::prelude::{Startup, Update};
        app.add_systems(Startup, setup_vehicles);
        app.add_systems(Update, update_vehicle_rankings);
        app.add_systems(Update, reset_vehicle_positions);
        app.add_systems(Update, resolve_checkpoints);
        app.add_systems(Update, update_vehicle_physics);
    }
}

//////////////////////////////////////////////////////////////////////

#[derive(Clone, PartialEq)]
enum Player {
    One,
    Two,
    Three,
}

impl fmt::Display for Player {
    fn fmt(&self, buffer: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Player::One => write!(buffer, "P1"),
            Player::Two => write!(buffer, "P2"),
            Player::Three => write!(buffer, "P3"),
        }
    }
}

#[derive(Clone)]
struct LapStat {
    top_start: Duration,
    checkpoint_to_tops: HashMap<u8, Duration>,
    top_finish: Duration,
}

impl LapStat {
    fn from(top: Duration) -> Self {
        Self {
            top_start: top,
            checkpoint_to_tops: HashMap::new(),
            top_finish: top,
        }
    }

    fn elapsed_secs(&self) -> f32 {
        if self.top_start == Duration::MAX || self.top_finish == Duration::MAX {
            return 0.0;
        }
        if self.top_start == self.top_finish {
            return 0.0;
        }
        assert!(self.top_start != Duration::MAX);
        assert!(self.top_finish != Duration::MAX);
        assert!(self.top_start < self.top_finish);
        (self.top_finish - self.top_start).as_secs_f32()
    }
}

#[derive(Component, Clone)]
struct BoatData {
    player: Player,
    position_initial: Vec2,
    position_previous: Vec2,
    position_current: Vec2,
    angle_current: f32,
    current_stat: LapStat,
    maybe_last_stat: Option<LapStat>,
    maybe_best_stat: Option<LapStat>,
    lap_count: u32,
}

impl BoatData {
    fn from_player_and_position(player: Player, pos: Vec3) -> Self {
        Self {
            player,
            position_initial: pos.xz(),
            position_previous: pos.xz(),
            position_current: pos.xz(),
            angle_current: PI,
            current_stat: LapStat::from(Duration::MAX),
            maybe_last_stat: None,
            maybe_best_stat: None,
            lap_count: 0,
        }
    }
    fn reset(&mut self) {
        self.position_previous = self.position_initial.clone();
        self.position_current = self.position_initial.clone();
        self.angle_current = PI;
        self.current_stat = LapStat::from(Duration::MAX);
        self.lap_count = 0;
    }
}

#[derive(Component)]
struct StatusMarker;

#[derive(Component)]
struct FirstPlaceMarker;

fn setup_vehicles(
    mut commands: Commands,
    mut materials: ResMut<Assets<StandardMaterial>>,
    server: Res<AssetServer>,
    tracks: Res<Assets<Track>>,
) {
    use bevy::color::Color;
    use bevy::prelude::JustifyText;
    use bevy::prelude::Node;
    use bevy::prelude::PositionType;
    use bevy::prelude::Text;
    use bevy::prelude::TextColor;
    use bevy::prelude::TextFont;
    use bevy::prelude::TextLayout;
    use bevy::prelude::UiRect;
    use bevy::prelude::Val;

    info!("** setup_vehicles **");

    let my_mesh: Handle<Mesh> = server.load(MODEL_ASSET_PATH);

    let Some(track) = tracks.get(&TRACK_CURRENT_HANDLE) else {
        return;
    };

    assert!(track.is_looping);

    let initial_righthand = track.initial_forward.cross(track.initial_up);
    let pos_p1 = track.initial_position;
    let pos_p2 = track.initial_position + initial_righthand * track.initial_left / 2.0;
    let pos_p3 = track.initial_position + initial_righthand * track.initial_right / 2.0;

    commands.spawn((
        Mesh3d(my_mesh.clone()),
        MeshMaterial3d(materials.add(StandardMaterial {
            base_color: Color::from(COLOR_P1),
            ..StandardMaterial::default()
        })),
        Transform::from_scale(Vec3::ONE * 0.15),
        BoatData::from_player_and_position(Player::One, pos_p1),
    ));
    commands.spawn((
        Mesh3d(my_mesh.clone()),
        MeshMaterial3d(materials.add(StandardMaterial {
            base_color: Color::from(COLOR_P2),
            ..StandardMaterial::default()
        })),
        Transform::from_scale(Vec3::ONE * 0.15),
        BoatData::from_player_and_position(Player::Two, pos_p2),
    ));
    commands.spawn((
        Mesh3d(my_mesh),
        MeshMaterial3d(materials.add(StandardMaterial {
            base_color: Color::from(COLOR_P3),
            ..StandardMaterial::default()
        })),
        Transform::from_scale(Vec3::ONE * 0.15),
        BoatData::from_player_and_position(Player::Three, pos_p3),
    ));

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
        TextColor(GOLD.into()),
        FirstPlaceMarker,
    ));

    commands
        .spawn(Node {
            position_type: PositionType::Absolute,
            top: Val::Px(5.0),
            right: Val::Px(5.0),
            ..Node::default()
        })
        .with_children(|parent| {
            let node = Node {
                margin: UiRect {
                    left: Val::Px(15.0),
                    ..UiRect::default()
                },
                ..Node::default()
            };
            let font = TextFont {
                font_size: 16.0,
                ..TextFont::default()
            };
            let layout = TextLayout::new_with_justify(JustifyText::Right);
            parent.spawn((
                Text::new("$$status_p1$$"),
                font.clone(),
                layout,
                node.clone(),
                TextColor(COLOR_P1.into()),
                StatusMarker,
            ));
            parent.spawn((
                Text::new("$$status_p2$$"),
                font.clone(),
                layout,
                node.clone(),
                TextColor(COLOR_P2.into()),
                StatusMarker,
            ));
            parent.spawn((
                Text::new("$$status_p3$"),
                font.clone(),
                layout,
                node.clone(),
                TextColor(COLOR_P3.into()),
                StatusMarker,
            ));
        });
}

fn reset_vehicle_positions(mut boats: Query<&mut BoatData>, keyboard: Res<ButtonInput<KeyCode>>) {
    if keyboard.just_pressed(KeyCode::KeyR) {
        for mut boat in &mut boats {
            boat.reset();
        }
    }
}

fn update_vehicle_rankings(
    mut materials: ResMut<Assets<RacingLineMaterial>>,
    material_handles: Query<&MeshMaterial3d<RacingLineMaterial>>,
    boats: Query<&BoatData>,
    first_place_labels: Query<&mut Text, With<FirstPlaceMarker>>,
    tracks: Res<Assets<Track>>,
) {
    let Some(track) = tracks.get(&TRACK_CURRENT_HANDLE) else {
        return;
    };

    assert!(track.is_looping);

    // sort by best lap
    let mut sorted_lap_duration_boats: Vec<(Duration, &BoatData)> = vec![];
    for boat in boats {
        let Some(best_stat) = &boat.maybe_best_stat else {
            continue;
        };
        assert!(best_stat.top_start != Duration::MAX);
        assert!(best_stat.top_finish != Duration::MAX);
        assert!(best_stat.top_start < best_stat.top_finish);
        let lap_duration = best_stat.top_finish - best_stat.top_start;
        sorted_lap_duration_boats.push((lap_duration, boat));
    }
    sorted_lap_duration_boats.sort_by_key(|(duration, _)| duration.clone());

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

    // update labels
    const RANK_NAMES: [&str; 3] = ["1st", "2nd", "3rd"];
    assert!(sorted_lap_duration_boats.len() < RANK_NAMES.len());
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
    for mut first_place_label in first_place_labels {
        *first_place_label = label.clone().into();
    }
}

fn resolve_checkpoints(
    mut boats: Query<&mut BoatData>,
    status_labels: Query<&mut Text, With<StatusMarker>>,
    tracks: Res<Assets<Track>>,
    time: Res<Time>,
) {
    let Some(track) = tracks.get(&TRACK_CURRENT_HANDLE) else {
        return;
    };

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
        if Segment::clips(closest_segment.item, &query_segment) {
            boat.position_previous = closest_segment.item.mirror(boat.position_previous);
            boat.position_current = closest_segment.item.mirror(boat.position_current);
        }
    }

    // update crossed checkpoints
    let top_now = time.elapsed();
    for mut boat in &mut boats {
        boat.current_stat.top_finish = top_now;
        let query_segment = Segment::from_endpoints(boat.position_current, boat.position_previous);
        let closest_segment = track.checkpoint_kdtree.nearest(&query_segment).unwrap();
        assert!(query_segment.ii == 255);
        assert!(closest_segment.item.ii != 255);
        if closest_segment.item.intersects(&query_segment) {
            if closest_segment.item.ii == 0 {
                if boat.current_stat.top_start == Duration::MAX {
                    boat.current_stat.top_start = top_now;
                } else {
                    let mut crossed_all_checkpoints = true;
                    for kk in 1..track.checkpoint_count {
                        crossed_all_checkpoints &=
                            boat.current_stat.checkpoint_to_tops.contains_key(&kk);
                    }
                    if crossed_all_checkpoints {
                        warn!(
                            "player {} completed a lap in {:>6.3}",
                            boat.player,
                            boat.current_stat.elapsed_secs(),
                        );
                        boat.maybe_last_stat = Some(boat.current_stat.clone());
                        boat.maybe_best_stat = Some(match &boat.maybe_best_stat {
                            None => boat.current_stat.clone(),
                            Some(best_stat) => {
                                if boat.current_stat.elapsed_secs() < best_stat.elapsed_secs() {
                                    boat.current_stat.clone()
                                } else {
                                    best_stat.clone()
                                }
                            }
                        });
                        boat.lap_count += 1;
                        boat.current_stat = LapStat::from(top_now);
                    }
                }
            } else {
                boat.current_stat
                    .checkpoint_to_tops
                    .insert(closest_segment.item.ii, top_now);
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
            boat.current_stat.elapsed_secs(),
            match &boat.maybe_last_stat {
                None => 0.0,
                Some(stat) => stat.elapsed_secs(),
            },
            match &boat.maybe_best_stat {
                None => 0.0,
                Some(best_stat) => best_stat.elapsed_secs(),
            },
        ));

        for kk in 1..track.checkpoint_count {
            let foo = boat.current_stat.checkpoint_to_tops.get(&kk);
            let aa = if boat.player == Player::One {
                format!("#{} ", kk)
            } else {
                "".into()
            };
            let bb: String = match foo {
                Some(duration) => {
                    let duration = (*duration - boat.current_stat.top_start).as_secs_f32();
                    format!("{:>6.3}", duration)
                }
                None => "     C".into(),
            };
            let cc: String = match &boat.maybe_last_stat {
                Some(stat) => {
                    let stat_top = stat.checkpoint_to_tops.get(&kk).unwrap();
                    let stat_duration = (*stat_top - stat.top_start).as_secs_f32();
                    match foo {
                        Some(duration) => {
                            let duration = (*duration - boat.current_stat.top_start).as_secs_f32();
                            format!("{:>+5.3}", duration - stat_duration)
                        }
                        None => {
                            format!("{:>6.3}", stat_duration)
                        }
                    }
                }
                None => "     L".into(),
            };
            let dd: String = match &boat.maybe_best_stat {
                Some(stat) => {
                    let stat_top = stat.checkpoint_to_tops.get(&kk).unwrap();
                    let stat_duration = (*stat_top - stat.top_start).as_secs_f32();
                    match foo {
                        Some(duration) => {
                            let duration = (*duration - boat.current_stat.top_start).as_secs_f32();
                            format!("{:>+5.3}", duration - stat_duration)
                        }
                        None => {
                            format!("{:>6.3}", stat_duration)
                        }
                    }
                }
                None => "     B".into(),
            };
            ss.push(format!("{}{} {} {}", aa, bb, cc, dd));
        }

        *status_label = ss.join("\n").into();
    }
}

struct BoatPhysics {
    mass: f32,
    friction: Vec2,
    thrust: f32,
    brake: f32,
    turning_speed: f32,
    force: Vec2,
    dt: f32,
}

impl BoatPhysics {
    fn from_dt(dt: f32) -> Self {
        Self {
            mass: 100.0,                     // kg
            friction: Vec2::new(5e-2, 1e-2), // 0 <= f < 1
            thrust: 1500.0,                  // m / s^2 / kg ~ N
            brake: 800.0,                    // m / s^2 / kg ~ N
            turning_speed: 5.0 * PI / 4.0,   // rad / s
            force: Vec2::ZERO,               // m / s^2 /kg ~ N
            dt,                              // s
        }
    }
}

impl BoatPhysics {
    fn compute_next_pos(&self, pos_prev: Vec2, pos_current: Vec2, angle_current: f32) -> Vec2 {
        let accel = self.force / self.mass / 2.0;
        let pp = Mat2::from_angle(angle_current);
        let friction = pp.transpose() * Mat2::from_diagonal(self.friction) * pp;
        (2.0 * Mat2::IDENTITY - friction) * pos_current
            - (1.0 * Mat2::IDENTITY - friction) * pos_prev
            + accel * self.dt * self.dt
    }
}

fn update_vehicle_physics(
    mut boats: Query<(&mut BoatData, &mut Transform)>,
    time: Res<Time>,
    keyboard: Res<ButtonInput<KeyCode>>,
    gamepads: Query<(Entity, &Gamepad)>,
) {
    let dt = time.delta_secs();
    for (mut boat, mut transform) in &mut boats {
        let pos_prev = boat.position_previous;
        let pos_current = boat.position_current;
        let mut physics = BoatPhysics::from_dt(dt);
        match boat.player {
            Player::One => {
                if keyboard.pressed(KeyCode::ArrowLeft) {
                    boat.angle_current += physics.turning_speed * dt;
                }
                if keyboard.pressed(KeyCode::ArrowRight) {
                    boat.angle_current -= physics.turning_speed * dt;
                }
                let dir_current = Vec2::from_angle(3.0 * PI / 2.0 - boat.angle_current);
                if keyboard.pressed(KeyCode::ArrowUp) {
                    physics.force += physics.thrust * dir_current;
                }
                if keyboard.pressed(KeyCode::ArrowDown) {
                    // physics.friction = Vec2::ONE * 0.10;
                    physics.force -= physics.brake * dir_current;
                }
            }
            Player::Three => {
                if keyboard.pressed(KeyCode::KeyA) {
                    boat.angle_current += physics.turning_speed * dt;
                }
                if keyboard.pressed(KeyCode::KeyD) {
                    boat.angle_current -= physics.turning_speed * dt;
                }
                let dir_current = Vec2::from_angle(3.0 * PI / 2.0 - boat.angle_current);
                if keyboard.pressed(KeyCode::KeyW) {
                    physics.force += physics.thrust * dir_current;
                }
                if keyboard.pressed(KeyCode::KeyS) {
                    // physics.friction = Vec2::ONE * 0.10;
                    physics.force -= physics.brake * dir_current;
                }
            }
            Player::Two => {
                for (_, gamepad) in &gamepads {
                    let left_stick_x = gamepad.get(GamepadAxis::LeftStickX).unwrap();
                    if left_stick_x.abs() > 0.01 {
                        boat.angle_current -= physics.turning_speed * left_stick_x * dt;
                    }
                    let dir_current = Vec2::from_angle(3.0 * PI / 2.0 - boat.angle_current);
                    if gamepad.pressed(GamepadButton::East) {
                        physics.force += physics.thrust * dir_current;
                    }
                    if gamepad.pressed(GamepadButton::North) {
                        // physics.friction = Vec2::ONE * 0.10;
                        physics.force -= physics.brake * dir_current;
                    }
                }
            }
        };
        let pos_next = physics.compute_next_pos(pos_prev, pos_current, boat.angle_current);
        boat.position_previous = boat.position_current;
        boat.position_current = pos_next;
        transform.translation = Vec3::new(pos_next.x, 0.0, pos_next.y);
        transform.rotation = Quat::from_axis_angle(Vec3::Y, boat.angle_current);
    }
}

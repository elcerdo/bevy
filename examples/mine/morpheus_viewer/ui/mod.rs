mod consts;

use consts::*;

use bevy::prelude::*;
use bevy::ui::RelativeCursorPosition;

static UI_WIDGETS: &[WidgetType] = &[
    WidgetType::Button(ButtonData::new("Reinit", 0)),
    WidgetType::Slider(SliderData::new("LR", 0)),
    WidgetType::Slider(SliderData {
        label: "Alpha",
        index: 1,
        ratio: 1.0,
    }),
];

pub struct UiPlugin;

impl Plugin for UiPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Startup, populate_ui_widgets);
        app.add_systems(Update, click_ui_widget_buttons);
        app.add_systems(Update, drag_ui_widget_sliders);
        app.add_systems(Update, update_ui_widget_sliders);
    }
}

fn populate_ui_widgets(mut commands: Commands) {
    let mut frame = commands.spawn(Node {
        width: Val::Percent(100.0),
        height: Val::Percent(100.0),
        top: Val::Px(10.0),
        left: Val::Px(10.0),
        flex_direction: FlexDirection::Column,
        ..default()
    });

    let mut make_widget = |widget: &WidgetType| match widget {
        WidgetType::Button(data) => {
            frame.with_children(|parent| {
                let mut container = parent.spawn((
                    Button,
                    Node {
                        border: UiRect::all(Val::Px(5.0)),
                        padding: UiRect::all(Val::Px(5.0)),
                        margin: UiRect::top(Val::Px(5.0)),
                        width: Val::Px(150.0),
                        ..default()
                    },
                    BorderColor(COLOR_UI_FG.into()),
                    BackgroundColor(COLOR_UI_BG.into()),
                    Interaction::None,
                    data.clone(),
                ));
                container.with_child((Text::new(data.label), TextColor(COLOR_UI_FG.into())));
            });
        }
        WidgetType::Slider(data) => {
            frame.with_children(|parent| {
                let mut container = parent.spawn((
                    Button,
                    Node {
                        border: UiRect::all(Val::Px(5.0)),
                        padding: UiRect::all(Val::Px(5.0)),
                        margin: UiRect::top(Val::Px(5.0)),
                        width: Val::Px(150.0),
                        ..default()
                    },
                    BorderColor(COLOR_UI_FG.into()),
                    BackgroundColor(COLOR_UI_BG.into()),
                    Interaction::None,
                    RelativeCursorPosition::default(),
                    data.clone(),
                ));
                container.with_child((
                    Node {
                        position_type: PositionType::Absolute,
                        top: Val::Px(0.0),
                        left: Val::Px(0.0),
                        height: Val::Percent(100.0),
                        width: Val::Percent(100.0 * data.ratio),
                        ..default()
                    },
                    BackgroundColor(COLOR_UI_SELECTED.into()),
                ));
                container.with_child((Text::new(data.label), TextColor(COLOR_UI_FG.into())));
            });
        }
    };

    for widget in UI_WIDGETS.iter() {
        make_widget(widget);
    }
}

fn click_ui_widget_buttons(
    mut query: Query<(&Interaction, &mut ButtonData), (Changed<Interaction>, With<Button>)>,
) {
    for (interaction, mut data) in &mut query {
        if matches!(*interaction, Interaction::Pressed) {
            data.count += 1;
        }
    }
}

fn drag_ui_widget_sliders(
    mut interaction_query: Query<
        (&Interaction, &RelativeCursorPosition, &mut SliderData),
        With<Button>,
    >,
) {
    for (interaction, relative_cursor, mut data) in &mut interaction_query {
        if !matches!(*interaction, Interaction::Pressed) {
            continue;
        }
        let Some(pos) = relative_cursor.normalized else {
            continue;
        };
        data.ratio = pos.x.clamp(0.0, 1.0);
    }
}

fn update_ui_widget_sliders(
    query: Query<(&Children, &SliderData), Changed<SliderData>>,
    mut node_query: Query<&mut Node, Without<Text>>,
) {
    for (children, data) in &query {
        let mut node_iter = node_query.iter_many_mut(children);
        if let Some(mut node) = node_iter.fetch_next() {
            node.width = Val::Percent(100.0 * data.ratio);
        }
    }
}

enum WidgetType {
    Button(ButtonData),
    Slider(SliderData),
}

#[derive(Clone, Component)]
pub struct ButtonData {
    label: &'static str,
    pub index: u32,
    pub count: u32,
}

impl ButtonData {
    pub const fn new(label: &'static str, index: u32) -> Self {
        Self {
            label,
            index,
            count: 0,
        }
    }
}

#[derive(Clone, Component)]
pub struct SliderData {
    label: &'static str,
    pub index: u32,
    pub ratio: f32,
}

impl SliderData {
    pub const fn new(label: &'static str, index: u32) -> Self {
        Self {
            label,
            index,
            ratio: 0.5,
        }
    }
}

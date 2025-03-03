use bevy::asset::{AssetServer, Assets};
use bevy::color::Srgba;
use bevy::math::{Affine2, Mat2, Vec2};
use bevy::pbr::StandardMaterial;

use bevy::prelude::MeshMaterial3d;
use bevy::prelude::{Component, Query, Res, ResMut, Time, With};

const COLOR_WAVY: Srgba = bevy::color::palettes::basic::BLUE;

pub fn make(asset_server: &Res<AssetServer>, scale: f32, angle: f32) -> StandardMaterial {
    use bevy::color::Color;
    use bevy::image::ImageAddressMode;
    use bevy::image::ImageLoaderSettings;
    use bevy::image::ImageSampler;
    use bevy::image::ImageSamplerDescriptor;
    use bevy::pbr::UvChannel;
    StandardMaterial {
        parallax_depth_scale: 0.1,
        perceptual_roughness: 0.2,
        base_color: Color::from(COLOR_WAVY),
        normal_map_channel: UvChannel::Uv1,
        normal_map_texture: Some(asset_server.load_with_settings(
            "textures/wavy_normal.png",
            |settings: &mut ImageLoaderSettings| {
                *settings = ImageLoaderSettings {
                    is_srgb: false,
                    sampler: ImageSampler::Descriptor(ImageSamplerDescriptor {
                        address_mode_u: ImageAddressMode::Repeat,
                        address_mode_v: ImageAddressMode::Repeat,
                        ..ImageSamplerDescriptor::default()
                    }),
                    ..ImageLoaderSettings::default()
                }
            },
        )),
        depth_map: Some(asset_server.load_with_settings(
            "textures/wavy_depth.png",
            |settings: &mut ImageLoaderSettings| {
                *settings = ImageLoaderSettings {
                    sampler: ImageSampler::Descriptor(ImageSamplerDescriptor {
                        address_mode_u: ImageAddressMode::Repeat,
                        address_mode_v: ImageAddressMode::Repeat,
                        ..ImageSamplerDescriptor::default()
                    }),
                    ..ImageLoaderSettings::default()
                }
            },
        )),
        uv_transform: Affine2::from_mat2(
            Mat2::from_diagonal(Vec2::ONE * scale) * Mat2::from_angle(angle),
        ),
        ..StandardMaterial::default()
    }
}

#[derive(Component)]
pub struct AnimatedWavyMarker;

pub fn animate(
    material_handles: Query<&MeshMaterial3d<StandardMaterial>, With<AnimatedWavyMarker>>,
    time: Res<Time>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    for material_handle in material_handles.iter() {
        if let Some(material) = materials.get_mut(material_handle) {
            material.uv_transform.translation.y += -0.8 * time.delta_secs();
        }
    }
}

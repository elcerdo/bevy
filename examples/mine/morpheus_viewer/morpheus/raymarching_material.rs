use crate::morpheus::slot::Slot;

use bevy::prelude::*;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};

use std::marker::PhantomData;

#[derive(Asset, TypePath, AsBindGroup, Clone)]
pub struct MorpheusRaymarchingMaterial<T: Slot> {
    #[texture(0)]
    #[sampler(1)]
    pub matcap_texture: Option<Handle<Image>>,
    #[uniform(2)]
    pub bbox_center: Vec3,
    phantom: PhantomData<T>,
}

impl<T: Slot> Material for MorpheusRaymarchingMaterial<T> {
    fn vertex_shader() -> ShaderRef {
        T::raymarching_shader()
    }

    fn fragment_shader() -> ShaderRef {
        T::raymarching_shader()
    }

    fn alpha_mode(&self) -> AlphaMode {
        AlphaMode::Blend
    }
}

impl<T: Slot> MorpheusRaymarchingMaterial<T> {
    pub fn new(matcap_texture: Handle<Image>) -> Self {
        Self {
            bbox_center: Vec3::ZERO,
            matcap_texture: Some(matcap_texture),
            phantom: PhantomData,
        }
    }
}

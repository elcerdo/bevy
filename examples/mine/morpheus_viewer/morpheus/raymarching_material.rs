use crate::morpheus::sdf::Sdf;

use bevy::prelude::*;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};

use std::marker::PhantomData;

#[derive(Asset, TypePath, AsBindGroup, Clone)]
pub struct MorpheusRaymarchingMaterial<T: Sdf> {
    #[texture(0)]
    #[sampler(1)]
    matcap_texture: Option<Handle<Image>>,
    #[uniform(2)]
    bbox_center: Vec3,
    phantom: PhantomData<T>,
}

impl<T: Sdf> Material for MorpheusRaymarchingMaterial<T> {
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

impl<T: Sdf> MorpheusRaymarchingMaterial<T> {
    pub fn new(center: Vec3, matcap_texture: Handle<Image>) -> Self {
        Self {
            bbox_center: center,
            matcap_texture: Some(matcap_texture),
            phantom: PhantomData,
        }
    }
}

use bevy::{
    asset::{io::Reader, AssetLoader, LoadContext},
    reflect::TypePath,
};

use bevy::prelude::*;

use thiserror::Error;

#[derive(Asset, TypePath, Debug)]
pub struct Snippet {
    pub content: String,
}

#[derive(Default)]
pub struct SnippetAssetLoader;

#[non_exhaustive]
#[derive(Debug, Error)]
pub enum SnippetAssetLoaderError {
    #[error("Could not load file: {0}")]
    Io(#[from] std::io::Error),
    #[error("Could not parse snippet: {0}")]
    Parse(#[from] std::string::FromUtf8Error),
}

impl AssetLoader for SnippetAssetLoader {
    type Asset = Snippet;
    type Settings = ();
    type Error = SnippetAssetLoaderError;

    async fn load(
        &self,
        reader: &mut dyn Reader,
        _settings: &(),
        _load_context: &mut LoadContext<'_>,
    ) -> Result<Self::Asset, Self::Error> {
        let mut bytes = Vec::new();
        reader.read_to_end(&mut bytes).await?;
        let content = String::from_utf8(bytes)?;
        Ok(Snippet { content })
    }
}

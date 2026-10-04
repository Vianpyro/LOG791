use std::str::FromStr;

#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct Id(String);

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InvalidId(String);

impl Id {
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl FromStr for Id {
    type Err = InvalidId;

    fn from_str(value: &str) -> Result<Self, Self::Err> {
        let is_valid = !value.is_empty()
            && value
                .bytes()
                .all(|b| matches!(b, b'a'..=b'z' | b'0'..=b'9' | b'-'));
        is_valid.ok_or_else(|| InvalidId(value.to_owned()))?;
        Ok(Self(value.to_owned()))
    }
}

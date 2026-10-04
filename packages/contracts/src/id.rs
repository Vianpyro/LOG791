use std::{error::Error, fmt, str::FromStr};

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

impl fmt::Display for InvalidId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "invalid identifier {:?}: expected [a-z0-9-]+", self.0)
    }
}

impl Error for InvalidId {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keeps_a_valid_identifier() {
        assert_eq!(
            "log200-lab-1".parse::<Id>().unwrap().as_str(),
            "log200-lab-1"
        );
    }

    #[test]
    fn empty_is_invalid() {
        assert!("".parse::<Id>().is_err());
    }

    #[test]
    fn cannot_escape_the_course() {
        for value in [
            ".",
            "..",
            "../log200/x",
            "a/b",
            "a\\b",
            "/etc/passwd",
            "sum\n",
            " sum",
            "sum\0",
            "%2e%2e",
        ] {
            assert!(value.parse::<Id>().is_err(), "{value:?} was accepted");
        }
    }

    #[test]
    fn uppercase_and_accents_are_invalid() {
        assert!("Sum".parse::<Id>().is_err());
        assert!("énoncé".parse::<Id>().is_err());
    }
}

//! Standard I/O case comparison (ADR-0013, ADR-0018)

pub fn same_output(expected: &[u8], actual: &[u8]) -> bool {
    lines(expected).eq(lines(actual))
}

fn lines(output: &[u8]) -> impl Iterator<Item = &[u8]> {
    output
        .trim_ascii_end()
        .split(|&byte| byte == b'\n')
        .map(<[u8]>::trim_ascii_end)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn identical_outputs_match() {
        assert!(same_output(b"1\n", b"1\n"));
    }

    #[test]
    fn missing_final_newline_matches() {
        assert!(same_output(b"1\n", b"1"));
    }

    #[test]
    fn crlf_matches_lf() {
        assert!(same_output(b"1\r\n2\r\n", b"1\n2\n"));
    }

    #[test]
    fn trailing_spaces_match() {
        assert!(same_output(b"1 2\n", b"1 2  \t\n"));
    }

    #[test]
    fn trailing_blank_lines_match() {
        assert!(same_output(b"1\n", b"1\n\n \n"));
    }

    #[test]
    fn blank_output_matches_empty() {
        assert!(same_output(b"", b" \n\n"));
    }

    #[test]
    fn wrong_value_differs() {
        assert!(!same_output(b"1\n", b"2\n"));
    }

    #[test]
    fn extra_line_differs() {
        assert!(!same_output(b"1\n", b"1\n2\n"));
    }

    #[test]
    fn missing_line_differs() {
        assert!(!same_output(b"1\n2\n", b"1\n"));
    }

    #[test]
    fn leading_space_differs() {
        assert!(!same_output(b"1\n", b" 1\n"));
    }

    #[test]
    fn inner_blank_line_differs() {
        assert!(!same_output(b"1\n2\n", b"1\n\n2\n"));
    }
}

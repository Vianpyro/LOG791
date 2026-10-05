//! Standard I/O case outcome (ADR-0013, ADR-0018)

use crate::{Outcome, Verdict};

pub fn case_verdict(outcome: &Outcome, expected: &[u8]) -> Verdict {
    match outcome {
        Outcome::TimedOut => Verdict::TimedOut,
        Outcome::Exited { status, .. } if !status.success() => Verdict::Crashed,
        Outcome::Exited { stdout, .. } if same_output(expected, stdout) => Verdict::Passed,
        Outcome::Exited { .. } => Verdict::WrongAnswer,
    }
}

fn same_output(expected: &[u8], actual: &[u8]) -> bool {
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
    use std::process::ExitStatus;

    fn failure() -> ExitStatus {
        cfg_select! {
            unix => std::os::unix::process::ExitStatusExt::from_raw(1 << 8),
            windows => std::os::windows::process::ExitStatusExt::from_raw(1),
        }
    }

    fn exited(status: ExitStatus, stdout: &[u8]) -> Outcome {
        Outcome::Exited {
            status,
            stdout: stdout.to_vec(),
        }
    }

    #[test]
    fn right_output_passes() {
        let outcome = exited(ExitStatus::default(), b"1\n");
        assert_eq!(case_verdict(&outcome, b"1\n"), Verdict::Passed);
    }

    #[test]
    fn wrong_input_is_a_wrong_answer() {
        let outcome = exited(ExitStatus::default(), b"2\n");
        assert_eq!(case_verdict(&outcome, b"1\n"), Verdict::WrongAnswer);
    }

    #[test]
    fn failure_with_right_output_is_a_crash() {
        let outcome = exited(failure(), b"1\n");
        assert_eq!(case_verdict(&outcome, b"1\n"), Verdict::Crashed);
    }

    #[test]
    fn timeout_is_timed_out() {
        assert_eq!(case_verdict(&Outcome::TimedOut, b"1\n"), Verdict::TimedOut);
    }

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

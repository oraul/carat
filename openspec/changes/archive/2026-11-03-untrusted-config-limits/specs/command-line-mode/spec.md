# Spec Delta

## ADDED Requirements

### Requirement: Edit refuses what is not a regular file of bounded size
":e path", and every other way a file is opened in a window, SHALL refuse a directory with `"path" is a directory`, a FIFO, a device, or a socket with `"path" is not a file`, and a file of more than 67108864 bytes with `E484: Can't open file path: File too large`, each as an error, leaving the current window and buffer as they were. Opening SHALL never wait for a writer or read more than the limit.

#### Scenario: Edit a directory
- **WHEN** the user types ":e lib" and "lib" is a directory
- **THEN** the message row shows "\"lib\" is a directory" as an error and the current buffer is unchanged

#### Scenario: Edit a FIFO
- **WHEN** the user types ":e pipe" and "pipe" is a FIFO with no writer
- **THEN** the message row shows "\"pipe\" is not a file" as an error and the editor keeps running

#### Scenario: Edit a device
- **WHEN** the user types ":e /dev/zero"
- **THEN** the message row shows "\"/dev/zero\" is not a file" as an error

#### Scenario: Edit a huge file
- **WHEN** the user types ":e big.bin" and "big.bin" holds 67108865 bytes
- **THEN** the message row shows "E484: Can't open file big.bin: File too large" as an error

#### Scenario: A linked regular file opens
- **WHEN** the user types ":e link.txt" and "link.txt" is a symbolic link to a regular file
- **THEN** the file opens as any other file

# Adventures — Project Configuration

A text-first RPG where you type whatever you want to do, and the world translates
your intent into hand-authored, consequential events. Every encounter won by the
right decisive move, not by grinding.

## Project Metadata

| Field | Value |
|-------|-------|
| **Status** | Pre-Production — Concept Complete |
| **Phase** | Engine Setup → Prototype |
| **Team Size** | 2–4 |
| **Session Length** | ~15–30 min per adventure |
| **Platforms** | PC (Steam/Epic), Web, Mobile (iOS/Android) |

## Technology Stack

- **Engine**: Flutter 3.44.0
- **Language**: Dart 3.12
- **Build System**: Flutter SDK / pub (pubspec.yaml)
- **Asset Pipeline**: Flutter asset bundling + custom JSON Scene Model pipeline
- **Architecture**: Thin cross-platform Flutter client + backend AI translation service

## Engine Version Reference

@docs/engine-reference/flutter/VERSION.md

## Technical Standards

@.claude/docs/technical-preferences.md
@.claude/docs/coding-standards.md

## Development Process

@.claude/docs/coordination-rules.md

## Quick Start

Commands, agent routing, and first steps: `.claude/docs/quick-start.md`
Game concept, pillars, and MVP scope: `design/gdd/game-concept.md`

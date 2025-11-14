# Voting Feature

This module manages all voting-related functionality in the El Visionat app, providing a complete system for users to vote on football matches and view voting statistics.

## Overview

The voting system allows registered users to:

- Vote on multiple matches within a "jornada" (matchday)
- View real-time vote counts for all matches
- Track voting periods and deadlines
- Access voting history and statistics

## Architecture

### Models

- **`VoteModel`**: Core data model representing a user's vote for a specific match

### Services

- **`VoteService`**: Handles all voting-related business logic and Firestore operations
  - Submit votes with validation
  - Retrieve vote counts and statistics
  - Manage voting periods and restrictions

### Providers

- **`VoteProvider`**: State management for voting functionality
  - Real-time vote count updates via StreamBuilder
  - User vote status tracking
  - Voting period validation
  - Integration with AuthProvider for user authentication

### Widgets

- **`VotingSection`**: Main voting interface component
  - Responsive design (mobile/desktop layouts)
  - Real-time vote count display
  - Voting period status indicator
- **`VotingCard`**: Individual match voting card
  - Team information and match details
  - Vote submission interface
  - Real-time vote count updates
- **`JornadaHeader`**: Header component displaying matchday information
  - Jornada number and metadata
  - Voting period status
  - Match count and statistics

## Data Flow

1. **Vote Submission**: User interacts with VotingCard → VoteProvider → VoteService → Firestore
2. **Real-time Updates**: Firestore → VoteProvider (StreamBuilder) → UI components
3. **Authentication**: AuthProvider integration ensures only registered users can vote

## Firebase Integration

### Firestore Collections

- `votes/{jornadaId}_{userId}`: Individual user votes
- `vote_counts/{jornadaId}_{matchId}`: Aggregated vote counts
- `voting_meta/jornada_{num}`: Voting period metadata

### Cloud Functions

- `onVoteWrite`: Triggers on vote submission to update aggregated counts
- Vote validation and duplicate prevention
- Real-time vote count synchronization

## Usage

```dart
import 'package:el_visionat/features/voting/index.dart';

// Display voting interface
VotingSection()

// Access vote provider in a widget
Consumer<VoteProvider>(
  builder: (context, voteProvider, child) {
    return VotingCard(match: match);
  },
)
```

## Key Features

- **Real-time Updates**: Live vote counts using Firestore streams
- **Responsive Design**: Optimized for both mobile and desktop
- **Vote Validation**: Prevents duplicate votes and validates voting periods
- **Performance Optimized**: Efficient state management and minimal rebuilds
- **Accessibility**: Full screen reader support and keyboard navigation

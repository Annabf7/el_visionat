// ============================================================================
// Index - Punt d'Entrada de les Cloud Functions
// ============================================================================
// Aquest fitxer importa les funcions individuals dels seus mòduls
// i les exporta perquè Firebase les pugui desplegar i executar.
// ============================================================================

import * as admin from "firebase-admin";

// Initialize the Admin SDK once for all functions in this module
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// Import only existing function modules from src/auth and src/votes
import {lookupLicense} from "./auth/lookup_license";
import {requestRegistration} from "./auth/request_registration";
import {completeRegistration} from "./auth/complete_registration";
import {checkRegistrationStatus} from "./auth/check_registration_status";
import {onVoteWrite} from "./votes/on_vote_write";
import {sendRegistrationNotificationHttp} from "./email/send_registration_notification_http";
import {onRegistrationStatusUpdate} from "./auth/on_registration_status_update";
// Import the V2 callable wrapper so client httpsCallable('validateActivationToken')
// works correctly with europe-west1 region.
import {validateActivationTokenCallableV2} from "./auth/validate_activation_token";
import {resendActivationToken} from "./auth/resend_activation_token";
import {sendPasswordResetEmail} from "./auth/send_password_reset_email";
import {warmFunctions} from "./utils/warm_functions";
import {getYouTubeVideos} from "./youtube/getYouTubeVideos";
import {searchAddresses, getPlaceDetails, calculateDistance} from "./googlePlaces";

// FCBQ Integration - Scraping de dades de la Federació
import {
  fetchJornada,
  fetchMultipleJornades,
  clearJornadaCache,
  syncWeeklyVoting,
  triggerSyncWeeklyVoting,
  getActiveVotingJornada,
  closeSuggestions,
  forceProcessWinner,
  setupWeeklyFocus,
} from "./fcbq";

// Visionat - Sistema de jugades destacades amb votació
import {notifyRefereesOnThreshold} from "./visionat/notify_referees_on_threshold";
import {closeDebateOnOfficialComment} from "./visionat/close_debate_on_official_comment";
import {
  notifyCommentReply,
  notifyCommentLike,
} from "./visionat/notify_comment_interactions";
import {
  notifyUnwatchedClips,
  checkUnwatchedClipsHttp,
} from "./visionat/notify_unwatched_clips";

// Export functions with the exact names expected by the client
exports.lookupLicense = lookupLicense;
exports.requestRegistration = requestRegistration;
exports.completeRegistration = completeRegistration;
exports.checkRegistrationStatus = checkRegistrationStatus;
exports.onVoteWrite = onVoteWrite;
exports.sendRegistrationNotificationHttp = sendRegistrationNotificationHttp;
exports.onRegistrationStatusUpdate = onRegistrationStatusUpdate;
exports.validateActivationToken = validateActivationTokenCallableV2;
exports.resendActivationToken = resendActivationToken;
exports.sendPasswordResetEmail = sendPasswordResetEmail;
exports.warmFunctions = warmFunctions;
exports.getYouTubeVideos = getYouTubeVideos;
exports.searchAddresses = searchAddresses;
exports.getPlaceDetails = getPlaceDetails;
exports.calculateDistance = calculateDistance;

// FCBQ Integration exports
exports.fetchJornada = fetchJornada;
exports.fetchMultipleJornades = fetchMultipleJornades;
exports.clearJornadaCache = clearJornadaCache;

// FCBQ Voting Sync exports
exports.syncWeeklyVoting = syncWeeklyVoting;
exports.triggerSyncWeeklyVoting = triggerSyncWeeklyVoting;
exports.getActiveVotingJornada = getActiveVotingJornada;
exports.closeSuggestions = closeSuggestions;
exports.forceProcessWinner = forceProcessWinner;
exports.setupWeeklyFocus = setupWeeklyFocus;

// Visionat - Sistema de jugades destacades exports
exports.notifyRefereesOnThreshold = notifyRefereesOnThreshold;
exports.closeDebateOnOfficialComment = closeDebateOnOfficialComment;
exports.notifyCommentReply = notifyCommentReply;
exports.notifyCommentLike = notifyCommentLike;
exports.notifyUnwatchedClips = notifyUnwatchedClips;
exports.checkUnwatchedClipsHttp = checkUnwatchedClipsHttp;

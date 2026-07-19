/** Guardian-only contract. Never import this module in child routes or payloads. */
export type AdultExploratoryNoteDto = {
  taxonomyKey: string;
  taxonomyVersion: string;
  observations: string[];
  evidence: Record<string, number | string | boolean>;
  disclaimer: 'Illustrative only. This is not a diagnosis, assessment, prediction, or recommendation.';
  createdAt: string;
};

export const ADULT_NOTE_DISCLAIMER: AdultExploratoryNoteDto['disclaimer'] =
  'Illustrative only. This is not a diagnosis, assessment, prediction, or recommendation.';

/// <reference types="zxcvbn" />

type Identifier = string;
type Phrase = string;

interface Phrases {
	suggestions: Record<Identifier, Phrase>;
	warnings: Record<Identifier, Phrase>;
}

declare namespace zxcvbn {
	export class Feedback {
		static default_phrases: Phrases;
		readonly phrases: Required<Phrases>;
		readonly default_feedback: zxcvbn.ZXCVBNFeedback;
		
		constructor(phrases?: Partial<Phrases>);
		from_result(result: zxcvbn.ZXCVBNResult): zxcvbn.ZXCVBNFeedback;
	}
}

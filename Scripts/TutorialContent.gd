extends RefCounted
class_name TutorialContent

const GUIDE_SPEAKER := "Local Miner"

const FIRST_CONTACT_NODES := {
	"FC_001": {
		"speaker": GUIDE_SPEAKER,
		"text": "Well, flip me upside down, smack my bottom with a wooden spoon, and call me a bullfrog! You scared the bejeebies out of me, kid!",
		"continue_text": "Continue",
		"next": "FC_002",
	},
	"FC_002": {
		"speaker": GUIDE_SPEAKER,
		"text": "I haven't seen a newcomer to this galaxy in near enough three decades. What brings you all the way out here?",
		"continue_text": "Answer Him",
		"next": "FC_CHOICE_STORY",
	},
	"FC_CHOICE_STORY": {
		"speaker": GUIDE_SPEAKER,
		"text": "So, what's your story?",
		"choices": [
			{
				"id": "story_rags_to_riches",
				"text": "Gotta pay off this ship somehow, and I figured this would be a nice quiet place to make my fortune. Apparently it isn't as quiet as I hoped. You already take all the good stuff?",
			},
			{
				"id": "story_prove_daddy_wrong",
				"text": "I'm the youngest of 38 children, so I stole this old junk heap from my father's fleet and set off to make my own name. Now, which way to the treasure?",
			},
			{
				"id": "story_lone_miner",
				"text": "None of your darned business! Tell me how these controls work and leave me alone.\n[Skip Tutorial — Continue Alone]",
			},
		],
	},
	"FC_DADDY_RESPONSE": {
		"speaker": GUIDE_SPEAKER,
		"text": "Good… HEAVENS! Your mother must be quite the UNIT. Well, there aren't any lawmen this far out, so calm yourself. Plenty of booty to go around. Heh—one of your ma's catchphrases, I'm guessing. Snicker, snort, chortle… Ahem. Anyway, as I was saying.",
		"continue_text": "Continue",
		"next": "FC_AA_RESPONSE",
	},
	"FC_AA_RESPONSE": {
		"speaker": GUIDE_SPEAKER,
		"text": "Plenty of riches to go around in this galaxy if you're brave—or stupid—enough to go where the real treasure is. Many came before you, and the iron carcasses of the fallen are scattered all over this galaxy. Some got too greedy. Others just weren't prepared for what they found.",
		"continue_text": "Continue",
		"next": "FC_TUTORIAL_OFFER",
	},
	"FC_TUTORIAL_OFFER": {
		"speaker": GUIDE_SPEAKER,
		"text": "I've got a little time before the nanobots finish plugging all the holes my last trip to the inner system put in my ship. How about I set you off on the right foot and show you a few of the ropes?",
		"choices": [
			{
				"id": "accept_tutorial",
				"text": "I could use the help. Show me what to do.\n[Continue Tutorial]",
			},
			{
				"id": "decline_tutorial",
				"text": "I'll figure it out myself.\n[Skip Tutorial — Continue Alone]",
			},
		],
	},
	"FC_ACCEPT_1": {
		"speaker": GUIDE_SPEAKER,
		"text": "Kid, if you're anything like me, this galaxy looks like a gargantuan pot of gold waiting for you to swoop down and skim your share off the top. It can be—if you're patient and smart. But your starship is plumb out of fuel and looks like a wadded-up pile of garbage. You won't make it past the front door with that equipment. You're going to need better tech.",
		"continue_text": "Continue",
		"next": "FC_ACCEPT_2",
	},
	"FC_ACCEPT_2": {
		"speaker": GUIDE_SPEAKER,
		"text": "Tell you what: I sent over a shallow scan of the planet. Dig around, get used to the mining controls, pick up some ore, and I'll check back with a little care package. Keep an eye on your fuel and hull integrity. Run dry or fall farther than that hull can handle, and your story ends like all the poor souls who came before.",
		"continue_text": "Begin Mining",
		"terminal_action": "start_guided_tutorial",
	},
	"FC_LONE_RESPONSE": {
		"speaker": GUIDE_SPEAKER,
		"text": "Well, excuse me, stranger! I was only trying to be friendly. Since you seem to know what you're doing, I'll send along a sensor sweep of the surface and a little care package, then leave you to it. Good luck—the galaxy isn't as quiet as it seems.",
		"continue_text": "Continue Alone",
		"terminal_action": "skip_tutorial",
	},
}

const CARE_PACKAGE_TEXT := (
	"Well, that wasn't so bad, was it? Looks like you've got the hang of the mining vehicle—and you've even got enough cargo aboard to upgrade your sensor suite. "
	+ "I'm sending down a fabricator module for your Lander so you can process what you mine and start upgrading that bag of bolts. Head back to the Lander and I'll show you how to use the Fabricator."
)

const UI_EXPLAINER_STEPS := {
	"ui_refuel": {
		"speaker": GUIDE_SPEAKER,
		"text": "Great, you made it back. Let me walk you through the controls here. There's a warehouse full of useful information, but we'll start with the essentials. These two buttons will be worn out in no time. Go ahead and refuel your mining rig.",
		"allowed_action": "lander.refuel",
		"highlight_actions": ["lander.refuel", "lander.repair"],
		"next": "ui_repair_info",
	},
	"ui_repair_info": {
		"speaker": GUIDE_SPEAKER,
		"text": "Good! If you've taken any hull damage, you can repair it with the Repair button below the fuel button.",
		"highlight_actions": ["lander.repair"],
		"continue_text": "Continue",
		"next": "ui_resources",
	},
	"ui_resources": {
		"speaker": GUIDE_SPEAKER,
		"text": "Your fuel and repair materials are pulled from your Lander Shuttle, but those fuel tanks aren't endless—and if you don't have the raw materials, the repair bots can't do anything for you. You'll have to refine resources from different planets to replenish your supplies.",
		"continue_text": "Continue",
		"next": "ui_subspace_net",
	},
	"ui_subspace_net": {
		"speaker": GUIDE_SPEAKER,
		"text": "If you have credits, you can purchase what you need from the subspace net. I'm not sure how that dark-magic tomfoolery works, but when I hit 'buy,' it appears out of nowhere, neatly stacked in my cargo hold.",
		"continue_text": "Continue",
		"next": "ui_lander_tab",
	},
	"ui_lander_tab": {
		"speaker": GUIDE_SPEAKER,
		"text": "But who am I kidding? You're not here to spend credits! You're here to watch that number get bigger—and I'm talking real big. Head over to your Lander tab and take a look at your net worth.",
		"allowed_action": "navigation.lander",
		"highlight_actions": ["navigation.lander"],
		"next": "lander_basics_complete",
	},
}


static func get_first_contact_node(node_id: String) -> Dictionary:
	return FIRST_CONTACT_NODES.get(node_id, {}).duplicate(true)


static func get_ui_explainer_step(step_id: String) -> Dictionary:
	return UI_EXPLAINER_STEPS.get(step_id, {}).duplicate(true)

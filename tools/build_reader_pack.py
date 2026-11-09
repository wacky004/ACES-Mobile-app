"""Build the IT2205 handout reader pack.

The reader pack contains curated review outlines, key terms, and summary
tables for the eight handouts. The full handout text is read from the
existing `it2205.json` chunk asset, so it is not duplicated here.

Run from the project root:
    python tools/build_reader_pack.py
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "assets" / "handouts" / "it2205_reader.json"
CHUNKS = ROOT / "assets" / "handouts" / "it2205.json"


def section(section_id: str, title: str, page: int, bullets: list[str],
            table_ids: list[str] | None = None) -> dict:
    return {
        "id": section_id,
        "title": title,
        "page": page,
        "bullets": bullets,
        "tableIds": table_ids or [],
    }


def term(term_id: str, word: str, definition: str, page: int,
         aliases: list[str] | None = None, section_id: str = "") -> dict:
    return {
        "id": term_id,
        "term": word,
        "aliases": aliases or [],
        "definition": definition,
        "page": page,
        "sectionId": section_id,
    }


def table(table_id: str, title: str, headers: list[str], rows: list[list[str]],
          page: int, note: str = "") -> dict:
    return {
        "id": table_id,
        "title": title,
        "headers": headers,
        "rows": rows,
        "page": page,
        "note": note,
    }


HANDOUTS = [
    {
        "id": "prelim-01",
        "termId": "prelim",
        "number": "01",
        "title": "Introduction to CPE Laws and Professional Practice",
        "summary": "The Computer Engineering field, how it differs from Electrical Engineering and Computer Science, what computer engineers do, and the eight traits of professionalism.",
        "sections": [
            section("nature", "Nature of the Field Study", 1, [
                "CHED defines BSCpE as the science and technology of design, development, implementation, maintenance, and integration of software and hardware in modern computing systems and computer-controlled equipment.",
                "The goal is to match hardware and software to the technological, scientific, and administrative needs of businesses and industries.",
                "CPE integrates electrical engineering and computer science practices.",
                "Computers are built from electronic circuits, so CPE and EE are closely related.",
            ]),
            section("compare", "CPE vs. EE vs. CS", 1, [
                "In hardware, computer engineers build hardware while computer scientists generally do not.",
                "In software, computer scientists know more theory, programming languages, and operating systems.",
                "Computer engineers often work as programmers writing programs for computer-based systems.",
                "Computer scientists still know enough hardware to analyze system operations and interact with hardware engineers.",
            ], ["cpe-vs-ee-cs"]),
            section("characteristics", "Characteristics of a Computer Engineer", 1, [
                "Design computers, computer-based systems, and networks with both hardware and software, subject to trade-offs.",
                "Have depth of knowledge in mathematics and engineering sciences.",
                "Acquire and maintain preparation for professional practice.",
                "Be life-long learners because the computing field changes rapidly.",
            ]),
            section("duties", "What Computer Engineers Do", 1, [
                "Research software and computer hardware.",
                "Design and test processors, circuit boards, memory devices, and routers.",
                "Write and test software for mobile devices and computers.",
                "Design, set up, and test networks; manage operating systems; design robots; create programs for products from aircraft to surgical technology.",
            ]),
            section("professionalism", "Professionalism and its 8 Traits", 2, [
                "Professionalism is more than qualifications, knowledge, and skills; it also requires integrity, ethics, and trust.",
                "The essence is not just the job to be done but how the job is done.",
                "The eight traits are competence, knowledge, respect, emotional intelligence, integrity, appropriateness, conscientiousness, and confidence.",
            ], ["professionalism-traits"]),
            section("trait-details", "Trait Details", 2, [
                "Competence: the job gets done well; abilities match the role and results often exceed expectations.",
                "Knowledge: detailed, up-to-date, specialized knowledge that is put into action.",
                "Respect: politeness and good manners to everyone; consider needs and uphold rights.",
                "Emotional intelligence: stay professional under pressure and stay aware of others' feelings.",
                "Integrity: be true to your word and do not compromise values even when the road is harder.",
                "Appropriateness: dress, grooming, body language, speech, topics, and behavior.",
                "Conscientiousness: reliable, high standards, organized, accountable; not overwork or perfectionism.",
                "Confidence: well-founded confidence reassures, motivates, supports leadership, and encourages challenges.",
            ]),
        ],
        "tables": [
            table("cpe-vs-ee-cs", "CPE vs. Electrical Engineering vs. Computer Science", [
                "Aspect", "Computer Engineering", "Electrical Engineering", "Computer Science"
            ], [
                ["Hardware", "Builds hardware and integrates systems", "Designs electrical and electronic systems", "Generally does not build hardware"],
                ["Software", "Writes programs for computer-based systems", "Applies electrical/electronic design", "Studies theory, programming languages, and operating systems"],
                ["Focus", "Hardware and software trade-offs", "Electrical and electronic systems", "Computation and software"],
            ], 1),
            table("professionalism-traits", "Eight Core Characteristics of Professionalism", [
                "Characteristic", "Meaning"
            ], [
                ["Competence", "Gets the job done well; abilities match the role and results often exceed expectations."],
                ["Knowledge", "Develops up-to-date, specialized knowledge and puts it into action."],
                ["Respect", "Shows politeness and good manners to everyone and upholds their rights."],
                ["Emotional intelligence", "Stays professional under pressure and is aware of others' feelings."],
                ["Integrity", "Keeps true to their word and does not compromise values."],
                ["Appropriateness", "Knows what is appropriate in dress, speech, topics, and behavior."],
                ["Conscientiousness", "Is reliable, organized, accountable, and committed to high standards."],
                ["Confidence", "Shows well-founded confidence that reassures, motivates, and leads."],
            ], 2),
        ],
        "terms": [
            term("p01-cpe", "Computer Engineering", "A program that embodies the design, development, implementation, maintenance, and integration of software and hardware in modern computing systems and computer-controlled equipment.", 1, ["CPE"], "nature"),
            term("p01-cmo", "CHED BSCpE memorandum", "The CHED policies, standards, and guidelines for the Bachelor of Science in Computer Engineering.", 1, ["CHED CMO"], "nature"),
            term("p01-professionalism", "Professionalism", "A set of values, behaviors, and responsibilities in how specialist knowledge and skills are applied; requires integrity, ethics, and trust.", 2, [], "professionalism"),
            term("p01-competence", "Competence", "The ability to get the job done well, with abilities that match the role and results that often exceed expectations.", 2, [], "trait-details"),
            term("p01-knowledge", "Knowledge", "Detailed, up-to-date, often highly specialized knowledge that is put into action.", 2, [], "trait-details"),
            term("p01-respect", "Respect", "Being a role model of politeness and good manners to everyone, considering their needs and upholding their rights.", 2, [], "trait-details"),
            term("p01-eq", "Emotional intelligence", "Staying professional under pressure, managing emotions, and being aware of other people's feelings.", 2, ["EQ"], "trait-details"),
            term("p01-integrity", "Integrity", "Keeping true to your word and refusing to compromise your values, even when the road is harder.", 2, [], "trait-details"),
            term("p01-appropriateness", "Appropriateness", "Knowing what is appropriate in different situations, including dress, grooming, body language, speech, topics, and behavior.", 2, [], "trait-details"),
            term("p01-conscientiousness", "Conscientiousness", "Being reliable, setting high standards, planning and prioritizing work, and holding yourself accountable without perfectionism.", 3, [], "trait-details"),
            term("p01-confidence", "Confidence", "Well-founded confidence that reassures and motivates others, supports leadership, and encourages new challenges.", 3, [], "trait-details"),
            term("p01-lifelong", "Life-long learner", "A computer engineer who continuously updates knowledge and skills because the computing field changes rapidly.", 1, [], "characteristics"),
        ],
    },
    {
        "id": "prelim-02",
        "termId": "prelim",
        "number": "02",
        "title": "Computer Engineering & IT Laws",
        "summary": "Cybersecurity and data protection, the Philippine IT laws, cybercrime offenses, and the international agreements behind them.",
        "sections": [
            section("definitions", "Cybersecurity, Data Protection, and Cybercrime", 1, [
                "Cybersecurity is the practice of protecting systems, networks, and programs from digital attacks.",
                "Data protection is the process of safeguarding important information from corruption, compromise, or loss.",
                "IT law governs the digital dissemination of information and software, including computing and the Internet.",
                "Cybercrime is a crime committed with or using information and communication technologies.",
            ]),
            section("categories", "Budapest Convention Categories", 1, [
                "Crimes against the confidentiality, integrity, and availability of computer data and systems.",
                "Computer-related offenses.",
                "Content-related offenses.",
                "Crimes related to copyright and related rights infringements.",
            ]),
            section("ph-laws", "Philippine IT Laws", 1, [
                "RA 10175: Cybercrime Prevention Act of 2012.",
                "RA 8792: E-Commerce Act of 2000.",
                "RA 8484: Access Device Regulation Act of 1998.",
                "RA 4200: Anti-Wiretapping Law.",
                "RA 10173: Data Privacy Act of 2012, administered by the National Privacy Commission.",
                "RA 9775: Anti-Child Pornography Act of 2009.",
                "RA 9995: Anti-Photo and Voyeurism Act of 2009.",
                "The first recorded PH cybercrime was the 2000 I Love You virus by Onel de Guzman; it was initially dismissed because no cybercrime law existed.",
            ], ["ph-it-laws"]),
            section("offenses-a", "Offenses Against Data and Systems", 2, [
                "Illegal access: accessing a computer system without right.",
                "Illegal interception: intercepting non-public computer data transmissions without right.",
                "Data interference: altering, damaging, deleting, or deteriorating data, including introducing viruses.",
                "System interference: hindering or interfering with a computer or network's functioning.",
                "Misuse of devices: using, producing, selling, or distributing a computer program or password without right.",
                "Cyber-squatting: acquiring a domain name in bad faith to profit, mislead, destroy reputation, or deprive others.",
            ]),
            section("offenses-b", "Computer-related Offenses", 2, [
                "Computer-related forgery: inputting, altering, or deleting data without right, resulting in inauthentic data.",
                "Computer-related fraud: altering or deleting data or a program with fraudulent intent, causing damage.",
                "Computer-related identity theft: acquiring, using, misusing, transferring, or altering another person's identifying information without right.",
            ], ["cybercrime-offenses"]),
            section("international", "International IT Laws", 3, [
                "As of 2021, 154 countries (79%) had cybercrime legislation; Europe had 93% adoption and Asia-Pacific 55%.",
                "The Budapest Convention is the first international treaty on crimes committed via the Internet; it was drawn up by the Council of Europe in Strasbourg in November 2001 (Treaty #185).",
                "HIPCAR supports Caribbean countries in harmonizing ICT policies, legislation, and regulatory procedures.",
                "The Malabo Convention is the African Union convention on cyber security and personal data protection.",
            ], ["international-laws"]),
        ],
        "tables": [
            table("ph-it-laws", "Philippine IT Laws", ["Republic Act", "Law", "Main Purpose"], [
                ["RA 10175", "Cybercrime Prevention Act of 2012", "Punishes crimes committed against and through computer systems."],
                ["RA 8792", "E-Commerce Act of 2000", "Facilitates electronic transactions and recognizes electronic documents."],
                ["RA 8484", "Access Device Regulation Act of 1998", "Regulates access devices and punishes fraudulent use."],
                ["RA 4200", "Anti-Wiretapping Law", "Prohibits wiretapping and privacy violations in communication."],
                ["RA 10173", "Data Privacy Act of 2012", "Protects personal information; administered by the NPC."],
                ["RA 9775", "Anti-Child Pornography Act of 2009", "Defines and penalizes child pornography."],
                ["RA 9995", "Anti-Photo and Voyeurism Act of 2009", "Penalizes photo and video voyeurism."],
            ], 1),
            table("cybercrime-offenses", "Core Cybercrime Offenses", ["Offense", "Meaning"], [
                ["Illegal access", "Accessing all or part of a computer system without right."],
                ["Illegal interception", "Intercepting non-public computer data transmissions without right."],
                ["Data interference", "Altering, damaging, deleting, or deteriorating computer data without right."],
                ["System interference", "Hindering or interfering with a computer or network without right."],
                ["Misuse of devices", "Using, producing, selling, or distributing a computer program or password without right."],
                ["Cyber-squatting", "Acquiring a domain name in bad faith to profit, mislead, or deprive others."],
                ["Computer-related forgery", "Producing inauthentic data through unauthorized input, alteration, or deletion."],
                ["Computer-related fraud", "Causing damage through unauthorized data or program changes with fraudulent intent."],
                ["Computer-related identity theft", "Using another person's identifying information without right."],
            ], 2),
            table("international-laws", "International IT Instruments", ["Instrument", "Focus"], [
                ["Budapest Convention", "First international treaty on Internet and computer-network crimes; Council of Europe, November 2001."],
                ["HIPCAR", "Harmonization of ICT policies, legislation, and regulatory procedures in the Caribbean."],
                ["Malabo Convention", "African Union convention on cyber security and personal data protection."],
            ], 3),
        ],
        "terms": [
            term("p02-cybersecurity", "Cybersecurity", "The practice of protecting systems, networks, and programs from digital attacks.", 1, [], "definitions"),
            term("p02-data-protection", "Data protection", "Safeguarding important information from corruption, compromise, or loss.", 1, [], "definitions"),
            term("p02-it-law", "IT law", "The law of information technology, including computing and the Internet, governing digital dissemination of information and software.", 1, [], "definitions"),
            term("p02-cybercrime", "Cybercrime", "A crime committed with or using information and communication technologies.", 1, [], "definitions"),
            term("p02-budapest", "Budapest Convention", "The first international treaty on crimes committed via the Internet and other computer networks; Treaty #185, Council of Europe, November 2001.", 3, ["Convention on Cybercrime"], "international"),
            term("p02-ra10175", "RA 10175", "Cybercrime Prevention Act of 2012; addresses crimes committed against and through computer systems.", 1, ["Cybercrime Prevention Act"], "ph-laws"),
            term("p02-ra8792", "RA 8792", "E-Commerce Act of 2000; facilitates electronic transactions and recognizes electronic documents.", 1, ["E-Commerce Act"], "ph-laws"),
            term("p02-ra8484", "RA 8484", "Access Device Regulation Act of 1998; regulates access devices and punishes fraudulent acts.", 1, ["Access Device Regulation Act"], "ph-laws"),
            term("p02-ra4200", "RA 4200", "Anti-Wiretapping Law; prohibits wiretapping and privacy violations in communication.", 1, ["Anti-Wiretapping Law"], "ph-laws"),
            term("p02-ra10173", "RA 10173", "Data Privacy Act of 2012; protects personal information and is administered by the National Privacy Commission.", 2, ["Data Privacy Act"], "ph-laws"),
            term("p02-ra9775", "RA 9775", "Anti-Child Pornography Act of 2009; defines and penalizes child pornography.", 2, ["Anti-Child Pornography Act"], "ph-laws"),
            term("p02-ra9995", "RA 9995", "Anti-Photo and Voyeurism Act of 2009; penalizes photo and video voyeurism.", 2, ["Anti-Photo and Voyeurism Act"], "ph-laws"),
            term("p02-illegal-access", "Illegal access", "Accessing all or part of a computer system without right.", 2, [], "offenses-a"),
            term("p02-illegal-interception", "Illegal interception", "Intercepting non-public computer data transmissions without right.", 2, [], "offenses-a"),
            term("p02-data-interference", "Data interference", "Altering, damaging, deleting, or deteriorating computer data without right, including viruses.", 2, [], "offenses-a"),
            term("p02-system-interference", "System interference", "Hindering or interfering with a computer or network's functioning without right.", 2, [], "offenses-a"),
            term("p02-cybersquatting", "Cyber-squatting", "Acquiring a domain name in bad faith to profit, mislead, destroy reputation, or deprive others.", 2, [], "offenses-a"),
            term("p02-npc", "National Privacy Commission", "The agency that administers and implements the Data Privacy Act of 2012.", 2, ["NPC"], "ph-laws"),
        ],
    },
    {
        "id": "midterm-03",
        "termId": "midterm",
        "number": "03",
        "title": "Understanding Contemporary Issues",
        "summary": "Philippine and international incidents that show how cybercrime laws apply in practice.",
        "sections": [
            section("hontiveros", "Hontiveros Wiretapping Case", 1, [
                "On September 12, 2017, former Negros Oriental representative Jacinto 'Jing' Paras said Senator Risa Hontiveros was liable for wiretapping.",
                "Hontiveros presented a photo of Justice Secretary Vitaliano Aguirre II texting a 'CongJing' during a Senate probe on the killing of Kian delos Santos.",
                "Paras cited the Anti-Wiretapping Law (RA 4200).",
                "The case moved forward in December 2021; Hontiveros posted PHP36,000 bail and called the case baseless.",
            ]),
            section("bdo", "BDO Hacking and 'Mark Nagoyo'", 1, [
                "In December 2021, BDO users reported unauthorized transfers to the UnionBank account of 'Mark Nagoyo'.",
                "The NBI arrested five suspects and charged them under RA 8484 and RA 10175.",
                "Roneyln Panaligan acted as a verifier, pretending to conduct surveys and collecting IDs for PHP50 in prepaid credit.",
                "Clay Revillosa sold 800,000 mailing lists with login credentials for PHP30,000.",
                "Jherom Anthony Taupa sold a 'SCAMPAGE,' a GCash phishing site, for PHP2,000.",
                "Ifesincachi Fountain Anaekwe and Chukwuemeka Pete were described as the alleged brains who provided access devices.",
            ], ["ph-cases"]),
            section("comelec", "COMELEC Data Leak", 2, [
                "In 2016, 20-year-old IT graduate Paul Loui Biteng was suspected of hacking the COMELEC website and data.",
                "He was charged with illegal access, data interference, and misuse of devices.",
                "The incident exposed the personal information of 55 million Filipino voters and was called the biggest private data leak in Philippine history.",
                "Four years later, a Manila court dismissed the case after the prosecution failed to prove guilt beyond reasonable doubt.",
            ]),
            section("covid", "COVID-19 Fake News and Misinformation", 3, [
                "Eighty people were charged with pandemic-related cybercrimes since March 2020, including 52 for spreading fake news.",
                "The PNP recorded 121 criminal complaints from March 9, 2020 to August 9, 2021; 87 were filed in court.",
                "Charges included Article 154 of the Revised Penal Code, RA 10175, and Presidential Decree No. 90.",
            ]),
            section("international", "International Computer-related Issues", 3, [
                "Brazil's Ministry of Health suffered a ransomware attack in December 2021; Lapsus$ claimed 50TB of data was extracted and deleted.",
                "Robert Davies of the UK used crypters and remote administration tools (RATs) to spy on victims; he was jailed for 26 months.",
                "More than 106 million travelers to Thailand had personal details leaked in August 2021.",
                "Nepal registered 3,906 cybercrime cases in fiscal year 2020/21, including 2,003 women, 1,471 men, and 1,108 minors.",
            ], ["international-cases"]),
        ],
        "tables": [
            table("ph-cases", "Philippine Cases at a Glance", ["Case", "Issue", "Law or Lesson"], [
                ["Hontiveros wiretapping complaint", "Photo of a text exchange presented in a Senate speech", "RA 4200; privacy of communication"],
                ["BDO / Mark Nagoyo hacking", "Unauthorized bank transfers and phishing infrastructure", "RA 8484 and RA 10175"],
                ["COMELEC data leak", "Hacking and exposure of 55 million voters' data", "Illegal access, data interference, misuse of devices"],
                ["COVID-19 fake news", "False pandemic information on social media", "Article 154 RPC, RA 10175, PD 90"],
            ], 1),
            table("international-cases", "International Cases at a Glance", ["Case", "What Happened", "Lesson"], [
                ["Brazil Ministry of Health", "Ransomware; 50TB claimed extracted by Lapsus$", "Critical services are high-value targets"],
                ["UK cyber voyeur", "Crypters and RATs used to spy on victims", "Malware can be hidden from antivirus"],
                ["Thailand traveler leak", "106 million travelers' details exposed", "Large databases need protection"],
                ["Nepal cybercrime cases", "3,906 cases in FY 2020/21", "Cybercrime affects adults and minors"],
            ], 3),
        ],
        "terms": [
            term("m03-wiretapping", "Wiretapping", "Secretly overhearing or recording a private communication without the consent of all parties; covered by RA 4200.", 1, ["anti-wiretapping"], "hontiveros"),
            term("m03-mark-nagoyo", "Mark Nagoyo", "The name on a UnionBank account used to receive funds in the December 2021 BDO hacking incident.", 1, [], "bdo"),
            term("m03-scampage", "SCAMPAGE", "A phishing website imitating GCash, sold to harvest login details and MPINs.", 2, [], "bdo"),
            term("m03-comelec-leak", "COMELEC data leak", "The 2016 breach that exposed personal information of 55 million Filipino voters.", 3, ["COMELEC hack"], "comelec"),
            term("m03-fake-news", "Fake news", "False or misleading information spread through media and social platforms; pandemic cases were charged under several laws.", 3, [], "covid"),
            term("m03-ransomware", "Ransomware", "Malware that blocks access to data or systems until a ransom is paid; used against Brazil's Ministry of Health.", 3, [], "international"),
            term("m03-crypter", "Crypter", "Software that encrypts malware to help it bypass security programs.", 4, [], "international"),
            term("m03-rat", "Remote administration tool (RAT)", "Software that gives an attacker remote access to a victim's device.", 4, ["RAT"], "international"),
            term("m03-data-breach", "Data breach", "Unauthorized access to or exposure of personal or confidential data.", 3, [], "comelec"),
            term("m03-nbi", "National Bureau of Investigation", "The agency that investigated and charged the BDO hacking suspects.", 1, ["NBI"], "bdo"),
        ],
    },
    {
        "id": "midterm-04",
        "termId": "midterm",
        "number": "04",
        "title": "Analysis of the Current CPE & IT Field Using Case Study",
        "summary": "Case-study research: definition, steps, benefits, limitations, five types, examples, and its significance in CPE/IT.",
        "sections": [
            section("definition", "What Is a Case Study?", 1, [
                "A research methodology involving a detailed and intensive analysis of a particular event, situation, organization, or social unit.",
                "Case studies are best conceptualized by scope of interest, not by specific methods.",
                "A successful case study analyzes a real-life situation where existing problems are resolved and relates theory to practice.",
            ]),
            section("steps", "Steps in a Case Study", 1, [
                "Outline the purpose of the case study.",
                "Identify the problems.",
                "Select the major problems in the case.",
                "Suggest solutions to implement.",
                "Recommend the best solution.",
            ], ["case-steps"]),
            section("benefits", "Benefits of Case Studies", 1, [
                "Focuses researchers within the confines of space and time on a specific case.",
                "Allows collection of interviews, documents, observations, and surveys for an in-depth look.",
                "Provides a comprehensive understanding of a bounded unit so readers can learn from it.",
                "Allows transferability of lessons, unlike statistical generalization in quantitative studies.",
            ]),
            section("limitations", "Limitations of Case Studies", 1, [
                "The volume of data is difficult to organize, and analysis strategies must be planned carefully.",
                "Researchers may be tempted to veer away from the research focus.",
                "Reporting findings from multiple-case studies can be challenging.",
            ]),
            section("types", "Five Types of Case Study", 2, [
                "Collective: explores differences within and between cases to replicate findings; cases must be chosen carefully.",
                "Explanatory: explains presumed causal links in real-life interventions too complex for surveys or experiments.",
                "Descriptive: starts with a descriptive theory, observes subjects, and compares data to the theory.",
                "Exploratory: explores situations where the intervention has no clear, single set of outcomes.",
                "Instrumental: the case is secondary and supportive; it provides insight or helps refine a theory.",
            ], ["case-types"]),
            section("examples", "Examples and Significance", 2, [
                "Scheib's study on role stress among school music teachers is a collective case study.",
                "Joia's Web-based e-commerce community study in Brazil is an explanatory case study.",
                "Lotzkar and Bottorff's nurse-patient relationship study is exploratory.",
                "Luck's STAMP study on patient violence is instrumental.",
                "In CPE/IT, case studies help understand field behavior, find causes and solutions, answer complex questions, and give direction to technical advances.",
            ]),
        ],
        "tables": [
            table("case-types", "Case Study Types", ["Type", "Definition", "Example"], [
                ["Collective", "Explores differences within and between cases to replicate findings.", "Scheib: role stress in school music teachers"],
                ["Explanatory", "Explains causal links in complex real-life interventions.", "Joia: Web-based e-commerce community in Brazil"],
                ["Descriptive", "Starts with a descriptive theory, observes, and compares.", "Starts from an existing descriptive theory"],
                ["Exploratory", "Explores situations with no clear, single set of outcomes.", "Lotzkar & Bottorff: nurse-patient relationship"],
                ["Instrumental", "The case supports insight or theory refinement.", "Luck: STAMP patient violence indicators"],
            ], 2),
            table("case-steps", "Steps in a Case Study", ["Step", "Purpose"], [
                ["Outline the purpose", "Sets the guide and direction for the study."],
                ["Identify the problems", "Focuses on issues that can lead to a solution."],
                ["Select the major problems", "Narrows down problems that do not directly affect the study."],
                ["Suggest solutions", "Creates a better understanding of the outcome."],
                ["Recommend the best solution", "Covers most problems and explains how it will be applied."],
            ], 1),
        ],
        "terms": [
            term("m04-case-study", "Case study", "A research methodology involving a detailed and intensive analysis of a particular event, situation, organization, or social unit.", 1, [], "definition"),
            term("m04-collective", "Collective case study", "Explores differences within and between cases with the goal of replicating findings across cases.", 2, [], "types"),
            term("m04-explanatory", "Explanatory case study", "Explains presumed causal links in real-life interventions too complex for surveys or experiments.", 2, [], "types"),
            term("m04-descriptive", "Descriptive case study", "Starts with a descriptive theory, observes subjects, and compares gathered information to the theory.", 2, [], "types"),
            term("m04-exploratory", "Exploratory case study", "Explores situations in which the intervention has no clear, single set of outcomes.", 2, [], "types"),
            term("m04-instrumental", "Instrumental case study", "Uses a case for something other than understanding that case; the case supports insight or theory refinement.", 2, [], "types"),
            term("m04-transferability", "Transferability", "Applying lessons from a case to other situations; different from statistical generalization.", 1, [], "benefits"),
            term("m04-bounded", "Bounded unit", "A case with clear boundaries in space and time.", 1, [], "benefits"),
        ],
    },
    {
        "id": "prefinals-05",
        "termId": "prefinals",
        "number": "05",
        "title": "Responsibilities of Computer Engineers",
        "summary": "The ethical, professional, and social responsibilities of computer engineers, including human safety, sustainability, internet safety, and pro bono publico.",
        "sections": [
            section("ethics", "What Is Ethics?", 1, [
                "Ethics analyzes human actions from the perspective of good/evil or morally correct/wrong.",
                "It is concerned with rights, responsibilities, language, ethical living, and moral decisions.",
                "Ethical obligations go beyond laws; for example, privacy should be protected even before a privacy law exists.",
            ]),
            section("ethical", "Ethical Responsibilities", 1, [
                "Contribute to society and human well-being; protect human rights and minimize negative consequences.",
                "Avoid harm: prevent injury, loss of information or property, property damage, and environmental impacts.",
                "Give proper credit for intellectual property; do not take credit for others' ideas or work.",
                "Respect privacy: collect only necessary data, keep it accurate, define retention, and do not reuse it without consent.",
                "Be honest and trustworthy: make no deceptive claims and disclose limitations and conflicts of interest.",
                "Be fair and act not to discriminate based on race, sex, religion, age, disability, national origin, or similar factors.",
            ], ["ethical-responsibilities"]),
            section("professional", "Professional Responsibilities", 2, [
                "Strive for the highest quality, effectiveness, and dignity; excellence is the most important obligation.",
                "Acquire and maintain professional competence through study, seminars, courses, and professional organizations.",
                "Improve public understanding of computing and counter false views.",
                "Honor contracts, agreements, and assigned responsibilities; accept personal accountability.",
                "Access computing and communication resources only when authorized; unauthorized use is prohibited.",
            ], ["professional-responsibilities"]),
            section("social", "Social Responsibilities", 2, [
                "Human safety: protect public safety, health, and welfare; examples include robots for the elderly and sensors for gas leaks or chemicals.",
                "Environment and sustainability: dispose of e-waste correctly and develop machines that separate waste or improve life for animals and trees.",
                "Internet safety: develop systems that do not jeopardize information, privacy, or public content; enforce stricter rules and monitor harmful content.",
            ], ["social-responsibilities"]),
            section("pro-bono", "Pro Bono Publico", 4, [
                "Pro bono publico means 'for the public good.'",
                "Computer engineers should share expertise with individuals or organizations unable to access or pay for it.",
                "Examples include outreach programs, trainings, and the STI computer lab on wheels.",
                "The Antikythera mechanism is an early analog computer used to display astronomical information.",
            ]),
        ],
        "tables": [
            table("ethical-responsibilities", "Ethical Responsibilities", ["Responsibility", "Meaning"], [
                ["Contribute to society and well-being", "Protect human rights, respect cultural diversity, and minimize negative consequences of computing."],
                ["Avoid harm", "Prevent injury, loss of information or property, property damage, and environmental impacts."],
                ["Give proper credit for intellectual property", "Do not take credit for others' ideas or work, even without copyright or patent."],
                ["Respect privacy", "Collect only necessary data, keep it accurate, define retention, and do not reuse it without consent."],
                ["Be honest and trustworthy", "Do not make deceptive claims; disclose limitations and conflicts of interest."],
                ["Be fair and not discriminate", "Avoid discrimination based on race, sex, religion, age, disability, national origin, and similar factors."],
            ], 1),
            table("professional-responsibilities", "Professional Responsibilities", ["Responsibility", "Meaning"], [
                ["Highest quality, effectiveness, and dignity", "Excellence is the most important professional obligation."],
                ["Maintain professional competence", "Upgrade knowledge through study, seminars, and professional organizations."],
                ["Improve public understanding", "Share technical knowledge and counter false views about computing."],
                ["Honor contracts and responsibilities", "Accept personal accountability; ethical judgment is the final guide."],
                ["Access resources only when authorized", "No trespassing or unauthorized use of systems, accounts, or files."],
            ], 2),
            table("social-responsibilities", "Social Responsibilities", ["Area", "Meaning"], [
                ["Human safety", "Protect public safety, health, and welfare, such as robots for the elderly and danger sensors."],
                ["Environment and sustainability", "Dispose of e-waste correctly and develop waste-separating or life-improving machines."],
                ["Internet safety", "Protect information, privacy, and public content; enforce rules and monitor harmful content."],
            ], 3),
        ],
        "terms": [
            term("pf05-ethics", "Ethics", "The analysis of human actions from the perspective of good/evil or morally correct/wrong.", 1, [], "ethics"),
            term("pf05-harm", "Harm", "Injury or negative consequences such as loss of information or property, property damage, or environmental impacts.", 1, [], "ethical"),
            term("pf05-ip", "Intellectual property", "Ideas and work that must be credited to their creators, even without explicit copyright or patent protection.", 1, ["IP"], "ethical"),
            term("pf05-privacy", "Privacy", "Maintaining the privacy and integrity of personal data, including accuracy and protection from unauthorized access.", 1, [], "ethical"),
            term("pf05-honesty", "Honesty and trustworthiness", "Making no deceptive claims, disclosing limitations, and being honest about qualifications and conflicts of interest.", 2, [], "ethical"),
            term("pf05-discrimination", "Discrimination", "Unfair treatment based on race, sex, religion, age, disability, national origin, or similar factors.", 2, [], "ethical"),
            term("pf05-competence", "Professional competence", "Maintaining and upgrading technical knowledge through study, seminars, courses, and professional organizations.", 2, [], "professional"),
            term("pf05-authorized", "Authorized access", "Using computing and communication resources only with appropriate approval.", 2, [], "professional"),
            term("pf05-human-safety", "Human safety", "Protecting public safety, health, and welfare through responsible computing and engineering.", 3, [], "social"),
            term("pf05-environment", "Environment and sustainability", "Reducing e-waste and developing technology that protects the environment.", 3, [], "social"),
            term("pf05-internet-safety", "Internet safety", "Developing systems that do not jeopardize users' information, privacy, or public content.", 3, [], "social"),
            term("pf05-pro-bono", "Pro bono publico", "Latin for 'for the public good'; sharing technical expertise with those unable to access or pay for it.", 4, [], "pro-bono"),
            term("pf05-ewaste", "E-waste", "Discarded electronic devices and components that must be disposed of responsibly.", 3, [], "social"),
            term("pf05-antikythera", "Antikythera mechanism", "An early analog computer used to calculate and display astronomical information.", 2, [], "pro-bono"),
        ],
    },
    {
        "id": "prefinals-06",
        "termId": "prefinals",
        "number": "06",
        "title": "Professionalism at Work",
        "summary": "Five principles of professionalism, five professional skills, and five common workplace challenges.",
        "sections": [
            section("principles", "Five Principles of a Professional", 1, [
                "Communication: verbal and body language, e-etiquette, and the resources to develop communication skills.",
                "Teamwork: builds strong relationships and eliminates toxic work culture (drama, fighting, low morale, lack of communication, boss's fear).",
                "Critical thinking: analyze information, reach conclusions, make decisions, connect ideas, and evaluate arguments.",
                "Ethics: aligns behavior and fosters openness, partnership, and trust; employees feel secure.",
                "Humanness: innate values, unique talents, purpose, growth, work-life balance, kindness, and emotional availability.",
            ], ["principles"]),
            section("skills", "Professional Skills Required", 2, [
                "Leadership: communicate well, motivate, delegate, listen, and stay flexible; emotional intelligence matters.",
                "Interpersonal: build relationships, understand others, show real interest, and acknowledge expertise.",
                "Self-management: control thoughts, feelings, and actions; organize tasks and set goals.",
                "Problem solving: observe, judge, act quickly, research, and implement solutions.",
                "Open-mindedness: accept different backgrounds, cultures, technologies, and new ideas without taking them personally.",
            ], ["skills"]),
            section("challenges", "Workplace Challenges", 3, [
                "Communication challenges: different response times and lack of coordination; drop egos and set aside personal problems.",
                "Low employee motivation: seek support, HR activities, seminars, and alternative approaches; encourage curiosity.",
                "Difficult people: unhappy employees spread negativity; involve HR if needed and communicate with kindness.",
                "Lack of skill development: employees risk becoming outdated; seek trainings and seminars.",
                "Mental health challenges: negative environments, harassment, and bullying can cause depression and anxiety; time off and personal space matter.",
            ], ["challenges"]),
            section("conclusion", "Conclusion", 3, [
                "Applying professional skills in accordance with professional principles helps avoid and prevent workplace challenges.",
            ]),
        ],
        "tables": [
            table("principles", "Five Principles of Professionalism", ["Principle", "Focus"], [
                ["Communication", "Verbal, body language, e-etiquette, and clear expectations."],
                ["Teamwork", "Strong relationships and elimination of toxic work culture."],
                ["Critical thinking", "Analyzing information, evaluating arguments, and making sound decisions."],
                ["Ethics", "Aligned behavior, openness, partnership, trust, and security."],
                ["Humanness", "Innate values, purpose, growth, work-life balance, and kindness."],
            ], 1),
            table("skills", "Five Professional Skills", ["Skill", "Meaning"], [
                ["Leadership", "Communicate, motivate, delegate, listen, and solve problems."],
                ["Interpersonal", "Build good relationships and work well with others."],
                ["Self-management", "Control thoughts, feelings, and actions; organize and prioritize."],
                ["Problem solving", "Observe, judge, and act quickly to resolve difficulties."],
                ["Open-mindedness", "Accept different ideas, cultures, and technological changes."],
            ], 2),
            table("challenges", "Five Workplace Challenges", ["Challenge", "Suggested Response"], [
                ["Communication challenges", "Drop egos, talk about the problem, and set aside personal issues."],
                ["Low motivation", "Seek support, HR activities, seminars, and new approaches."],
                ["Difficult people", "Involve HR if needed; communicate, acknowledge feelings, and be kind."],
                ["Lack of skill development", "Seek trainings and seminars to stay relevant."],
                ["Mental health challenges", "Take time off, build personal space, and address harassment or bullying."],
            ], 3),
        ],
        "terms": [
            term("pf06-communication", "Communication", "Verbal and body language, e-etiquette, and the resources needed to communicate effectively at work.", 1, [], "principles"),
            term("pf06-teamwork", "Teamwork", "Working closely with others to build relationships and eliminate toxic work culture.", 1, [], "principles"),
            term("pf06-critical-thinking", "Critical thinking", "Analyzing information, reaching conclusions, and making sound decisions.", 1, [], "principles"),
            term("pf06-ethics", "Ethics", "A workplace principle that aligns behavior and fosters openness, partnership, trust, and security.", 1, [], "principles"),
            term("pf06-humanness", "Humanness", "Expressing innate human values, talents, purpose, growth, work-life balance, kindness, and emotional availability.", 2, [], "principles"),
            term("pf06-leadership", "Leadership", "Communicating well, motivating a team, delegating, listening, and staying flexible.", 2, [], "skills"),
            term("pf06-interpersonal", "Interpersonal skills", "Building good relationships and working well with groups and individuals.", 2, [], "skills"),
            term("pf06-self-management", "Self-management", "Controlling thoughts, feelings, and actions to maximize productivity and achieve goals.", 2, [], "skills"),
            term("pf06-problem-solving", "Problem solving", "Observing, judging, and acting quickly when difficulties arise.", 2, [], "skills"),
            term("pf06-open-mindedness", "Open-mindedness", "Accepting various ideas, behaviors, cultures, and technological changes.", 2, [], "skills"),
            term("pf06-toxic", "Toxic work culture", "A workplace characterized by drama, fighting, low morale, lack of communication, and fear of the boss.", 1, [], "principles"),
            term("pf06-mental-health", "Mental health", "Psychological well-being at work; harassment, bullying, and negative environments can harm it.", 3, [], "challenges"),
        ],
    },
    {
        "id": "finals-07",
        "termId": "finals",
        "number": "07",
        "title": "Computer Engineers at Work",
        "summary": "Computer Engineering as a profession, salary outlook, nine common job roles, and four challenges.",
        "sections": [
            section("profession", "Computer Engineering as a Profession", 1, [
                "Computer Engineering does not require a board licensure exam; graduates can enter the professional world immediately.",
                "Graduates are still expected to take certifications and trainings accredited by legitimate organizations.",
                "A CPE degree offers opportunities locally and overseas.",
            ]),
            section("salary", "Salary Outlook", 1, [
                "DOLE 2019: CPE ranked 7th among top-paying jobs with an average of PHP49,335 per month; programmers and systems analysts ranked 5th and 6th.",
                "US BLS 2020: $119,560 per year (about PHP6,147,476) for computer engineers; salary depends on experience and specialization.",
                "BLS projects 2% growth for CPE from 2019 to 2029 versus 4% for other computer jobs.",
                "Software engineering and web developing are projected to grow 22% and 8%, respectively.",
            ], ["salary-snapshot"]),
            section("roles", "Job Opportunities", 1, [
                "Technical Support Specialist: helps end-users with hardware, software, access, performance, and connection issues.",
                "Computer Programmer: turns designs into code, checks for errors, and rewrites until error-free.",
                "Web Developer: designs websites and web apps, integrates security, and manages site functionality.",
                "IT Consultant: helps clients use IT to solve problems and achieve business objectives.",
                "Information Systems Manager: oversees computer systems, networks, and technology work.",
                "Game Developer: oversees game development and writes code for characters, environments, and elements.",
                "Database Administrator: stores and protects company data and ensures secure access.",
                "Software Developer: creates flowcharts/models and participates in designing, building, maintaining, and testing software.",
                "Data Scientist: analyzes raw data using machine learning, statistics, and programming.",
            ], ["job-roles"]),
            section("challenges", "Challenges", 3, [
                "Slow skills development: schools lack industry equipment; take free seminars, online trainings, and focus on one or two skills.",
                "Expenses: trainings and certifications cost money; start with a job that fits current skills and save for future training.",
                "Competitive job opportunities: many applicants; an impressive resume, skills, interviews, and personality fit matter.",
                "Interactions: most of the day is spent at a computer; find the right time to interact, take breaks, and join after-work events.",
            ], ["career-challenges"]),
        ],
        "tables": [
            table("salary-snapshot", "Salary and Growth Snapshot", ["Metric", "Value"], [
                ["DOLE 2019 CPE rank", "7th top-paying job"],
                ["DOLE 2019 average monthly salary", "PHP49,335"],
                ["US BLS 2020 average yearly salary", "$119,560 (about PHP6,147,476)"],
                ["BLS 2019-2029 CPE growth", "2% (4% for other computer jobs)"],
                ["Software engineering growth", "22%"],
                ["Web developing growth", "8%"],
            ], 1),
            table("job-roles", "Nine Common CPE Roles", ["Role", "Main Duties", "Key Skills"], [
                ["Technical Support Specialist", "Assist end-users with hardware, software, and connection issues.", "Problem solving, interpersonal skills, OS proficiency, attention to detail"],
                ["Computer Programmer", "Write and debug code from software designs.", "Time management, OOP, databases/SQL, data structures"],
                ["Web Developer", "Build websites and web applications; integrate security.", "Problem solving, creativity, programming, web design"],
                ["IT Consultant", "Help clients use IT to meet business objectives.", "Hardware/software solutions, network maintenance, web support"],
                ["Information Systems Manager", "Oversee systems, networks, and technology staff.", "Analytical thinking, networking, system management"],
                ["Game Developer", "Develop games and code characters and environments.", "Passion for games, creativity, C#/C++"],
                ["Database Administrator", "Store, organize, and protect company data.", "Data manipulation, database design, organization"],
                ["Software Developer", "Design, build, maintain, and test software.", "JavaScript, Python, PHP, Ruby, Linux/Unix"],
                ["Data Scientist", "Analyze data with ML, statistics, and programming.", "Statistics, machine learning, deep learning, visualization"],
            ], 2),
            table("career-challenges", "Four CPE Career Challenges", ["Challenge", "Suggested Response"], [
                ["Slow skills development", "Free seminars, online trainings, self-study, and focus on one or two skills."],
                ["Expenses", "Take a job that fits current skills and save for future certifications."],
                ["Competitive job opportunities", "Build a strong resume, skills, interview presence, and personality fit."],
                ["Interactions", "Use breaks and after-work events to socialize without distracting others."],
            ], 3),
        ],
        "terms": [
            term("f07-board", "Board licensure exam", "A government exam required for some professions; Computer Engineering does not require one for practice.", 1, [], "profession"),
            term("f07-dole", "DOLE", "Department of Labor and Employment; its 2019 Labor Market Trends ranked CPE 7th among top-paying jobs.", 1, ["Department of Labor and Employment"], "salary"),
            term("f07-bls", "Bureau of Labor Statistics", "The US agency that reported the 2020 CPE salary and the 2019-2029 growth projection.", 1, ["BLS"], "salary"),
            term("f07-tech-support", "Technical Support Specialist", "A role that helps end-users with hardware, software, access, performance, and connection issues.", 1, [], "roles"),
            term("f07-programmer", "Computer Programmer", "A role that writes and debugs code from software designs until the program is error-free.", 2, [], "roles"),
            term("f07-web-dev", "Web Developer", "A role that designs websites and web applications and integrates security and features.", 2, [], "roles"),
            term("f07-consultant", "IT Consultant", "A role that helps clients use information technology to solve problems and meet business goals.", 2, [], "roles"),
            term("f07-is-manager", "Information Systems Manager", "A role that oversees a company's computer systems, networks, and technology staff.", 2, [], "roles"),
            term("f07-game-dev", "Game Developer", "A role that oversees video game development and codes characters, environments, and elements.", 2, [], "roles"),
            term("f07-dba", "Database Administrator", "A role that stores, organizes, and protects company data from corruption, loss, and unauthorized access.", 2, ["DBA"], "roles"),
            term("f07-software-dev", "Software Developer", "A role that designs, builds, maintains, and tests software and creates models for programmers.", 3, [], "roles"),
            term("f07-data-scientist", "Data Scientist", "A role that analyzes raw data using machine learning, statistics, and programming to produce insights.", 3, [], "roles"),
            term("f07-competitive", "Competitive job opportunities", "A challenge where many applicants compete for the same role; resume, skills, interviews, and personality fit matter.", 3, [], "challenges"),
        ],
    },
    {
        "id": "finals-08",
        "termId": "finals",
        "number": "08",
        "title": "Application of IT Laws in the Computer Engineering Field",
        "summary": "Future innovations in Computer Engineering and five guidelines for applying IT laws and professional practice.",
        "sections": [
            section("future", "The Future of Computer Engineering", 1, [
                "Computer Engineering has been at the forefront of major technological advances: the Internet, smartphones, automated devices, and robotics.",
                "When done right, it helped put people on the moon with less computing power than today; when done wrong, errors caused commercial airline crashes.",
                "Today's mistakes can become existential threats, while successes can produce medicines and other advances.",
            ]),
            section("innovations", "Projected Innovations", 1, [
                "Smart factories: industrial IoT is limited by sensor energy and battery life; Everactive sensors can run over 20 years with minimal maintenance.",
                "VR and AR: immersive remote work, collaboration, education, and spontaneity; Facebook prototypes and PwC growth projections.",
                "Self-driving cars: require safety, reliability, high-powered sensors, intuitive HCI, and backups; ALKS could prevent 47,000 serious accidents over a decade.",
                "Spaceflight: alternative propulsion, subsurface water instruments, HCI, and semi-autonomous drones; Perseverance and Ingenuity landed on Mars on February 18, 2021.",
                "GPT-3: OpenAI's powerful autocomplete; used for search, code, music, and medical queries, but it makes mistakes and needs hard engineering.",
            ], ["innovations"]),
            section("professional-practice", "Grounded Professional Practice", 2, [
                "IT laws keep ethical behavior checked, grounded, and balanced.",
                "Computer engineering professionals have a moral responsibility to ground their outputs and technological achievements in existing IT laws.",
                "Apply the five guidelines below when planning projects, building systems, and working with others.",
            ]),
            section("guidelines", "IT Laws and Professional Practice Guidelines", 2, [
                "Plan projects for the common good, especially for underprivileged groups, water, electricity, or mental health.",
                "Be professional: practice integrity and ethics and keep the work environment free from conflicts.",
                "Aim for bigger targets: be a pioneer and inventor, create next trends, take risks, and make society function better.",
                "Think outside the box: use creative alternatives, avoid e-waste, do not pass off altered programs as original, and buy used working hardware.",
                "Be observant: report blatant motivations that cross what is morally correct; if you are reported, comply and admit faults.",
            ], ["guidelines"]),
        ],
        "tables": [
            table("innovations", "Projected Innovations", ["Innovation", "Description"], [
                ["Smart factories", "Industrial IoT sensors with long battery life; Everactive sensors run over 20 years."],
                ["VR and AR", "Immersive remote work and collaboration; Facebook prototypes and projected growth."],
                ["Self-driving cars", "Safety, sensors, HCI, and backups; ALKS could prevent 47,000 serious accidents over a decade."],
                ["Spaceflight", "Alternative propulsion, water-detection instruments, HCI, and drones; Perseverance and Ingenuity."],
                ["GPT-3", "Powerful autocomplete for search, code, music, and medical queries; not perfect and needs hard engineering."],
            ], 1),
            table("guidelines", "Five IT Law Guidelines", ["Guideline", "Meaning"], [
                ["Plan for the common good", "Create systems and devices that help society, especially underprivileged groups."],
                ["Be professional", "Use integrity and ethics and keep the work environment free from conflicts."],
                ["Aim for bigger targets", "Be a pioneer, create next trends, take risks, and make society function better."],
                ["Think outside the box", "Use creative alternatives, avoid e-waste, and do not pass off altered programs as original."],
                ["Be observant", "Report morally wrong or illegal work; comply and admit faults if you are reported."],
            ], 2),
        ],
        "terms": [
            term("f08-smart-factories", "Smart factories", "Factories using industrial IoT sensors and automation; limited by sensor energy and battery life.", 1, [], "innovations"),
            term("f08-iot", "Internet of Things (IoT)", "A network of connected sensors and devices that collect and exchange data.", 1, ["IoT"], "innovations"),
            term("f08-everactive", "Everactive", "A startup that developed industrial sensors running over 20 years with minimal maintenance.", 1, [], "innovations"),
            term("f08-vrar", "VR and AR", "Virtual reality and augmented reality; immersive technologies for remote work, collaboration, and education.", 1, ["VR/AR"], "innovations"),
            term("f08-alks", "Automated Lane Keeping Systems (ALKS)", "Driver-assistance systems that could prevent an estimated 47,000 serious accidents over a decade.", 1, ["ALKS"], "innovations"),
            term("f08-ingenuity", "Ingenuity", "NASA's Mars Helicopter that landed with Perseverance on February 18, 2021 and pilots itself due to communication delays.", 2, ["Mars Helicopter"], "innovations"),
            term("f08-gpt3", "GPT-3", "OpenAI's generative pre-trained transformer described as the most powerful autocomplete ever invented.", 2, ["GPT-3"], "innovations"),
            term("f08-common-good", "Common good", "The principle of creating systems and devices that benefit society and underprivileged groups.", 2, [], "guidelines"),
            term("f08-outside-box", "Think outside the box", "Using creative alternatives, avoiding e-waste, and not passing off altered programs as original.", 3, [], "guidelines"),
            term("f08-observant", "Be observant", "Report morally wrong or illegal work and comply with rules if you are reported.", 3, [], "guidelines"),
        ],
    },
]


def validate() -> None:
    if len(HANDOUTS) != 8:
        raise ValueError(f"Expected 8 handouts, got {len(HANDOUTS)}")
    handout_ids = set()
    term_ids = set()
    table_ids = set()
    for handout in HANDOUTS:
        hid = handout["id"]
        if hid in handout_ids:
            raise ValueError(f"Duplicate handout id: {hid}")
        handout_ids.add(hid)
        if len(handout["sections"]) < 4:
            raise ValueError(f"{hid}: expected at least 4 sections")
        if len(handout["terms"]) < 6:
            raise ValueError(f"{hid}: expected at least 6 terms")
        if len(handout["tables"]) < 1:
            raise ValueError(f"{hid}: expected at least 1 table")
        local_tables = {table["id"] for table in handout["tables"]}
        for table in handout["tables"]:
            if table["id"] in table_ids:
                raise ValueError(f"Duplicate table id: {table['id']}")
            table_ids.add(table["id"])
            if len(table["headers"]) < 2:
                raise ValueError(f"{table['id']}: needs at least 2 headers")
            if not table["rows"]:
                raise ValueError(f"{table['id']}: no rows")
            for row in table["rows"]:
                if len(row) != len(table["headers"]):
                    raise ValueError(f"{table['id']}: row length mismatch")
        for section in handout["sections"]:
            if section["page"] not in range(1, 6):
                raise ValueError(f"{hid}/{section['id']}: bad page")
            for table_id in section["tableIds"]:
                if table_id not in local_tables:
                    raise ValueError(f"{hid}/{section['id']}: unknown table {table_id}")
            if not section["bullets"]:
                raise ValueError(f"{hid}/{section['id']}: no bullets")
        for entry in handout["terms"]:
            if entry["id"] in term_ids:
                raise ValueError(f"Duplicate term id: {entry['id']}")
            term_ids.add(entry["id"])
            if not entry["term"].strip() or not entry["definition"].strip():
                raise ValueError(f"{hid}/{entry['id']}: empty term or definition")
            if entry["page"] not in range(1, 6):
                raise ValueError(f"{hid}/{entry['id']}: bad page")

    if not CHUNKS.exists():
        raise ValueError("Run build_handout_chunks.py first")
    chunk_data = json.loads(CHUNKS.read_text(encoding="utf-8"))
    chunk_handouts = {chunk["handoutId"] for chunk in chunk_data["chunks"]}
    missing = handout_ids - chunk_handouts
    if missing:
        raise ValueError(f"Handouts missing full-text chunks: {missing}")
    print(f"Validated {len(HANDOUTS)} handouts, {len(term_ids)} terms, "
          f"{len(table_ids)} tables")


def main() -> None:
    validate()
    payload = {
        "subjectId": "it2205",
        "subject": "Computer Engineering Laws and Discipline",
        "version": "1.0.0",
        "handouts": HANDOUTS,
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    main()

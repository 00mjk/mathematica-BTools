(* ::Package:: *)

(* Autogenerated Package *)

(* ::Section:: *)
(*Git Connections*)



Git::usage=
	"A general head for all Git actions";


SVN::usage=
	"A general head for all SVN actions";


GitHub::usage=
	"A connection to the GitHub functinality";


Begin["`Private`"];


(* ::Subsection:: *)
(*Git*)



$gitactions:=
	KeyMap[ToLowerCase]@$GitActions;


PackageAddAutocompletions[
	"Git",
	{
		Keys@$GitActions,
		{"Options", "Function"}
		}
	]


(* ::Subsubsection::Closed:: *)
(*Git*)



Git//Clear


(* ::Subsubsubsection::Closed:: *)
(*Options*)



Git[
	command_?(KeyMemberQ[$gitactions,ToLowerCase@#]&),
	"Options"
	]:=
	Options@$gitactions[ToLowerCase[command]];


(* ::Subsubsubsection::Closed:: *)
(*Function*)



Git[
	command_?(KeyMemberQ[$gitactions,ToLowerCase@#]&),
	"Function"
	]:=
	$gitactions[ToLowerCase[command]];


(* ::Subsubsubsection::Closed:: *)
(*Command*)



Git[
	command_?(KeyMemberQ[$gitactions,ToLowerCase@#]&),
	args:Except[_?OptionQ]...,
	ops:OptionsPattern[],
	"Command"
	]:=
	Block[{$GitRunFlags=Append[$GitRunFlags, "ReturnCommand"->True]},
		Git[command, args, ops]
		];


(* ::Subsubsubsection::Closed:: *)
(*Known*)



$GitParamMap["Git"]=
	{
		"GitVersion"->"version",
		"GitHelp"->"help",
		"GitCallFrom"->"C",
		"GitConfig"->"c",
		"GitExecPath"->"exec-path",
		"GitHTMLPath"->"html-path",
		"GitManPath"->"man-path",
		"GitInfoPath"->"info-path",
		"GitPaginate"->"paginate",
		"GitNoPager"->"no-pager",
		"GitDir"->"git-dir",
		"GitWorkTree"->"work-tree",
		"GitNamespace"->"namespace",
		"GitSuperPrefix"->"super-prefix",
		"GitBare"->"bare",
		"GitNoReplaceObjects"->"no-replace-objects",
		"GitLiteralPathSpecs"->"literal-pathspecs",
		"GitGlobalPathSpecs"->"glob-pathspecs",
		"GitNoglobPathSpecs"->"noglob-pathspecs",
		"GitIcasePathSpecs"->"icase-pathspecs"
		};


Options[Git]=
	Thread[Keys@$GitParamMap["Git"]->Automatic];
Git[
	command_?(KeyMemberQ[$gitactions,ToLowerCase@#]&),
	args:Except[_?OptionQ]...,
	ops:OptionsPattern[]
	]:=
	Block[
		{
			$GitBaseOptionArgs=
				GitPrepParams[
					Git,
					FilterRules[{ops}, Options[Git]],
					$GitParamMap["Git"]
					],
			opsNew=
				Sequence@@
					DeleteCases[{ops}, 
						Apply[Alternatives, Options[Git]]->_
						]
			},
		With[{cmd=$gitactions[ToLowerCase[command]]},
			With[{r=cmd[args, opsNew]},
				r/;Head[r]=!=cmd
				]
			]
		];


(* ::Subsubsubsection::Closed:: *)
(*Fallback*)



Git::badcmd=
	"Couldn't execute command `` with parameters ``";
Git[
	cmd_String,
	args___
	]:=
	Block[
		{
			$GitBaseOptionArgs=
				GitPrepParams[
					Git,
					FilterRules[Select[{args}, OptionQ], Options[Git]],
					$GitParamMap["Git"]
					],
			argNew=Sequence@@DeleteCases[{args}, Apply[Alternatives, Options[Git]]->_]
			},
		With[{r=GitRun[cmd, argNew]},
			If[Head[r]===GitRun,
				Message[Git::badcmd, cmd, {args}]
				];
			r/;Head[r]=!=GitRun
			]
		];


(* ::Subsection:: *)
(*SVN*)



(* ::Subsubsection::Closed:: *)
(*SVN*)



$svnactions:=
	KeyMap[ToLowerCase]@$SVNActions


PackageAddAutocompletions[
	"SVN",
	{
		Keys[$SVNActions]
		}
	]


SVN[
	command_?(KeyMemberQ[$svnactions,ToLowerCase@#]&),
	args___
	]:=
	With[{cmd=$svnactions[ToLowerCase[command]]},
		With[{r=cmd[args]},
			r/;Head[r]=!=cmd
			]
		];
SVN[
	cmd_String,
	args___
	]:=
	SVNRun[cmd,args];


(* ::Subsection:: *)
(*GitHub*)



(* ::Subsubsection::Closed:: *)
(*GitHub*)



(* ::Subsubsubsection::Closed:: *)
(*Autocompletions*)



$githubactions:=
	KeyMap[ToLowerCase]@$GitHubActions


PackageAddAutocompletions[
	"GitHub",
	{
		Keys[$GitHubActions],
		{"Options", "Function"}
		}
	]


(* ::Subsubsubsection::Closed:: *)
(*Function*)



GitHub//Clear


GitHub[
	command_String?(KeyMemberQ[$githubactions,ToLowerCase@#]&),
	"Function"
	]:=
	$githubactions[ToLowerCase[command]];


(* ::Subsubsubsection::Closed:: *)
(*Options*)



GitHub[
	command_String?(KeyMemberQ[$githubactions,ToLowerCase@#]&),
	"Options"
	]:=
	Options@Evaluate@$githubactions[ToLowerCase[command]];


(* ::Subsubsubsection::Closed:: *)
(*HTTPRequest*)



GitHub[
	command_String?(KeyMemberQ[$githubactions,ToLowerCase@#]&),
	args:Except[_?OptionQ]...,
	opp___?OptionQ,
	"HTTPRequest"
	]:=
	GitHub[command, args, opp, "ReturnGitHubQuery"->True];


(* ::Subsubsubsection::Closed:: *)
(*HTTPResponse*)



GitHub[
	command_String?(KeyMemberQ[$githubactions,ToLowerCase@#]&),
	args:Except[_?OptionQ]...,
	opp___?OptionQ,
	"HTTPResponse"
	]:=
	URLRead@
		GitHub[command, args, opp, 
			"GitHubImport"->False,
			"ReturnGitHubQuery"->True
			];


(* ::Subsubsubsection::Closed:: *)
(*ResultJSON*)



GitHub[
	command_String?(KeyMemberQ[$githubactions,ToLowerCase@#]&),
	args:Except[_?OptionQ]...,
	opp___?OptionQ,
	"ResultJSON"
	]:=
	Import[GitHub[command, args, opp, "HTTPResponse"], "JSON"];


(* ::Subsubsubsection::Closed:: *)
(*ImportedResult*)



GitHub[
	command_String?(KeyMemberQ[$githubactions,ToLowerCase@#]&),
	args:Except[_?OptionQ]...,
	opp___?OptionQ,
	"ImportedResult"
	]:=
	GitHub[command, args, opp, "GitHubImport"->True];


(* ::Subsubsubsection::Closed:: *)
(*Main*)



GitHub[
	command_String?(KeyMemberQ[$githubactions,ToLowerCase@#]&),
	args:Except[_?OptionQ]...,
	opp___?OptionQ
	]:=
	Block[{$GitHubRepoFormat=True},
		With[
			{
				cmd=$githubactions[ToLowerCase@command],
				ropp=Sequence@@FilterRules[{opp}, Except["GitHubImport"]]
				},
			With[
				{
					r=
						If[Options[cmd]=!={},
							cmd[args, Sequence@@FilterRules[{opp}, Options@cmd]],
							With[{c=cmd[args, ropp]},
								If[Head@c===cmd,
									cmd[args],
									c
									]
								]
							]
					},
				Replace[r,
					h_HTTPRequest:>
						Which[
							TrueQ@Lookup[{opp}, "ReturnGitHubQuery", False],
								r,
							Lookup[{opp}, "GitHubImport", $GitHubImport]===False, 
								h, 
							True,
								GitHubImport@URLRead[h]
							]
					]/;Head[r]=!=cmd
				]
			]
		];


GitHub[
	path:{___String}|_String:{},
	query:(_String->_)|{(_String->_)...}:{},
	headers:_Association:<||>,
	opp___?OptionQ
	]:=
	Block[{$GitHubRepoFormat=True},
		If[
			Lookup[{opp}, "GitHubImport", $GitHubImport]=!=False, 
			GitHubImport, 
			Identity
			]@
			URLRead[
				GitHubQuery[
					path,
					query,
					headers
					]
				]
		];


End[];




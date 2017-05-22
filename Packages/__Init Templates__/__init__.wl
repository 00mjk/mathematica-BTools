(* ::Package:: *)

(* ::Title:: *)
(*$Name`*)


(* ::Text::GrayLevel[0.5]:: *)
(* Autogenerated $Name loader file *)


BeginPackage["$Name`"];


(* ::Section:: *)
(* Package Functions *)


Begin["`Private`Package`"];
$InitCode


(* ::Subsection::Closed:: *)
(* End[] *)


End[];


(* ::Section:: *)
(* Load *)


`Private`Package`$loadAbort=False;
CheckAbort[
	`Private`Package`feHiddenBlock[
		`Private`Package`appLoad[]
		],
	`Private`Package`$loadAbort=True;
	EndPackage[]
	];
If[!`Private`Package`$loadAbort,
	If[$Notebooks,
		If[FileExistsQ@`Private`Package`appPath["LoadInfo.m"],
			Replace[Quiet[Import@`Private`Package`appPath["LoadInfo.m"],Import::nffil],
				`Private`Package`specs:{__Rule}|_Association:>
					With[{
						`Private`Package`preloads=
							Replace[
								Lookup[`Private`Package`specs,"PreLoad"],
								Except[{__String}]->{}
								],
						`Private`Package`hide=
							Replace[
								Lookup[`Private`Package`specs,"Hidden"],
								Except[{__String}]->{}
								]
						},
						`Private`Package`appGet/@`Private`Package`preloads;
						If[
							!MemberQ[`Private`Package`hide,
								Replace[
									FileNameSplit@
										FileNameDrop[#,
											FileNameDepth@
												`Private`Package`appPath["Packages"]
											],{
									{f_}:>{StringTrim[f,".m"|".wl"]}|StringTrim[f,".m"|".wl"],
									{p__,f_}:>
										{p,StringTrim[f,".m"|".wl"]}
									}]
								],
							`Private`Package`feUnhidePackage@#
							]&/@Keys@`Private`Package`$DeclaredPackages
						]
				]
			];
		];
	EndPackage[];
	];

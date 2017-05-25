(* ::Package:: *)

$packageHeader

(* ::Section:: *)
(*PacletTools*)



(* ::Subsubsection::Closed:: *)
(*Paclets*)



PacletInfo::usage=
	"Extracts the Paclet from a PacletInfo.m file";
PacletInfoAssociation::usage=
	"Converts a Paclet into an Association";
PacletExpression::usage=
	"Generates a Paclet expression for a directory";
PacletExpressionBundle::usage=
	"Bundles a PacletExpression into a PacletInfo.m file";
PacletBundle::usage=
	"Bundles a paclet site from a directory in a standard build directory";


PacletLookup::usage=
	"Applies Lookup to paclets";
PacletOpen::usage=
	"Opens an installed paclet from its \"Location\"";


(* ::Subsubsection::Closed:: *)
(*Paclet Sites*)



PacletSiteURL::usage=
	"Provides the default URL for a paclet site";
PacletSiteInfo::usage=
	"Extracts a PacletSite from a .paclet or PacletSite.mz file";
PacletSiteInfoDataset::usage=
	"Formats a PacletSite into a Dataset";
PacletSiteBundle::usage=
	"Bundles a PacletSite.mz from a collection of PacletInfo specs";


(* ::Subsubsection::Closed:: *)
(*Installers*)



PacletInstallerURL::usage=
	"Provides the default URL for a paclet installer";
PacletUploadInstaller::usage=
	"Uploads the paclet installer script";
PacletUninstallerURL::usage=
	"Provides the default URL for a paclet installer";
PacletUploadUninstaller::usage=
	"Uploads the paclet installer script";


(* ::Subsubsection::Closed:: *)
(*Uploads*)



PacletAPIUpload::usage=
	"Creates a paclet link via an API based upload";


PacletUpload::usage=
	"Uploads a paclet to a server";
PacletSiteInstall::usage=
	"Installs from the Installer.m file if possible";
PacletSiteUninstall::usage=
	"Uninstalls from the Uninstaller.m file if possible";


(* ::Subsubsection::Closed:: *)
(*Downloads*)



(*PacletDownload::usage=
	"Downloads pieces of a paclet from a server";*)


Begin["`Private`"];


$PacletBuildRoot=$TemporaryDirectory;
$PacletBuildExtension=
	"_paclets";
$PacletExtension="paclets";


(* ::Subsection:: *)
(*Paclets*)



PacletInfoAssociation[PacletManager`Paclet[k__]]:=
	With[{o=Options[PacletExpression]},
		KeySortBy[First@FirstPosition[o,#]&]
		]@
		With[{base=
			KeyMap[Replace[s_Symbol:>SymbolName[s]],<|k|>]
			},
			ReplacePart[base,
				"Extensions"->
					AssociationThread[
						First/@base["Extensions"],
						Association@*Rest/@base["Extensions"]
						]
				]
			];
PacletInfoAssociation[infoFile_]:=
	Replace[PacletInfo[infoFile],{
		p:PacletManager`Paclet[__]:>
			PacletInfoAssociation@p,
		_-><||>
		}];
PacletInfo[infoFile_]:=
	With[{pacletInfo=
		Replace[infoFile,{
			d:(_String|_File)?DirectoryQ:>
				FileNameJoin@{d,"PacletInfo.m"},
			f:(_String|_File)?(FileExtension[#]=="paclet"&):>
				With[{rd=CreateDirectory[]},
					First@ExtractArchive[f,rd,"*PacletInfo.m"]
					]
			}]
		},
		(If[
			StringContainsQ[
				Nest[DirectoryName,pacletInfo,3],
				$TemporaryDirectory
				]&&
					(
					DirectoryName@pacletInfo!=DirectoryName@infoFile),
				DeleteDirectory[Nest[DirectoryName,pacletInfo,2],DeleteContents->True]
				];#)&@
		If[FileExistsQ@pacletInfo,
			
			Begin["PacletManager`"];
			(End[];
				Map[
					Replace[#,
						(s_Symbol->v_):>
							(SymbolName[s]->v)
						]&,
					#])&@Import[pacletInfo],
			PacletManager`Paclet[]
			]
		];


Options[PacletDocsInfo]={
	"Language"->"English",
	"Root"->None,
	"LinkBase"->None,
	"MainPage"->None(*,
	"Resources"\[Rule]None*)
	};
PacletDocsInfo[ops:OptionsPattern[]]:=
	SortBy[DeleteCases[DeleteDuplicatesBy[{ops},First],_->None],
		With[{o=Options@PacletDocsInfo},Position[o,First@#]&]];
PacletDocsInfo[dest_String?DirectoryQ,ops:OptionsPattern[]]:=
	With[{lang=
		FileBaseName@
			SelectFirst[
				FileNames["*",FileNameJoin@{dest,"Documentation"}],
				DirectoryQ]},
		If[MissingQ@lang,
			{},
			PacletDocsInfo[ops,
				"Language"->
					lang,
				"MainPage"->
					Replace[
						Map[
							FileNameTake[#,-2]&,
							Replace[
								FileNames["*.nb",
									FileNameJoin@{dest,"Documentation",lang,"Guides"}],{
									{}:>
										FileNames["*.nb",
											FileNameJoin@{dest,"Documentation",lang},
											2]
								}]
							],{
						{}->None,
						p:{__}:>
							First@
								SortBy[StringTrim[p,".nb"],
									EditDistance[FileBaseName@dest,FileBaseName@#]&]
						}]
				]
			]
		];


Options[PacletExtensionData]={
	"Documentation"->Automatic,
	"Kernel"->Automatic,
	"FrontEnd"->Automatic,
	"Resource"->Automatic,
	"AutoCompletionData"->Automatic
	};
PacletExtensionData[pacletInfo_Association,dest_,ops:OptionsPattern[]]:=
	Merge[Merge[Last]]@{
		Replace[Lookup[pacletInfo,"Extensions"],
			Except[_Association?AssociationQ]:>
				<||>
			],
		{
			Replace[OptionValue["Documentation"],{
				Automatic:>
					If[Length@
							FileNames["*.nb",
									FileNameJoin@{dest,"Documentation"},
									\[Infinity]]>0,
						"Documentation"->
							PacletDocsInfo[dest],
						Nothing
						],
				r:_Rule|{___Rule}:>
					"Documentation"->Association@Flatten@{r},
				Except[_Association]->Nothing
				}],
			Replace[OptionValue["Kernel"],{
				Automatic:>
					"Kernel"->
						<|
								Root -> ".", 
								Context -> FileBaseName@dest<>"`"
								|>,
				r:_Rule|{___Rule}:>
					"Kernel"->Association@Flatten@{r},
				Except[_Association]->Nothing
				}],
			Replace[OptionValue["FrontEnd"],{
				Automatic:>
					If[Length@
							FileNames["*.nb",
									FileNameJoin@{dest,"FrontEnd"},
									\[Infinity]]>0,
							"FrontEnd"->
								If[
									DirectoryQ@
										FileNameJoin@{dest,
											"FrontEnd",
											"TextResources"
											}||
									DirectoryQ@
										FileNameJoin@{dest,
											"FrontEnd",
											"SystemResources"
											},
									<|Prepend->True|>,
									<||>
									],
							Nothing
							],
				r:_Rule|{___Rule}:>
					"FrontEnd"->Association@Flatten@{r},
				Except[_Association]->Nothing
				}],
			Replace[OptionValue["Resource"],{
				Automatic:>
					If[Length@
							Select[
								FileNames["*",
									FileNameJoin@{dest,"Data"},
									\[Infinity]],
								Not@DirectoryQ@#&&
									Not@StringMatchQ[FileNameTake@#,".DS_Store"]&
								]>0,
							"Resource"->
								<|
									"Root" -> "Data",
									"Resources" -> 
										Map[
											FileNameDrop[#,
												FileNameDepth[dest]+1
												]&,
											Select[
												FileNames["*",
													FileNameJoin@{dest,"Data"},
													\[Infinity]],
												Not@DirectoryQ@#&&
													Not@StringMatchQ[FileNameTake@#,".DS_Store"]&
												]
											]
									|>,
							Nothing
							],
				r:_Rule|{___Rule}:>
					"Resource"->Association@Flatten@{r},
				Except[_Association]->Nothing
				}],
			Replace[OptionValue["AutoCompletionData"],{
				Automatic:>
					If[Length@
							FileNames["*.tr"|"documentedContexts.m",
									FileNameJoin@{dest,"AutoCompletionData"},
									\[Infinity]]>0,
						"AutoCompletionData"->
							<|
								"Root" -> "AutoCompletionData"
								|>,
						Nothing
						],
				r:_Rule|{___Rule}:>
					"Documentation"->Association@Flatten@{r},
				Except[_Association]->Nothing
				}]
			}
		};


Options[PacletExpression]=
	Join[
		{
			"Name"->"MyPaclet",
			"Version"->Automatic,
			"Creator"->Automatic,
			"Description"->Automatic,
			"Root"->Automatic,
			"WolframVersion"->Automatic,
			"Internal"->Automatic,
			"Loading"->Automatic,
			"Qualifier"->Automatic,
			"BuildNumber"->Automatic,
			"Extensions"->Automatic
			},
		Options@PacletExtensionData
		];
PacletExpression[ops:OptionsPattern[]]:=
	PacletManager`Paclet@@
		SortBy[DeleteCases[DeleteDuplicatesBy[{ops},First],_->None],
			With[{o=Options@PacletExpression},Position[o,First@#]&]
			];


PacletExpression[dir]~~`Package`addUsage~~
	"generates a Paclet expression from dir";
PacletExpression[
	dest_String?DirectoryQ,
	ops:OptionsPattern[]]:=
	With[{pacletInfo=PacletInfoAssociation[dest]},
		PacletExpression[
			Sequence@@FilterRules[{ops},
				Except["Kernel"|"Documentation"|"Extensions"|"FrontEnd"]],
			"Name"->FileBaseName@dest,
			"Extensions"->
				Replace[OptionValue["Extensions"],{
					Automatic:>
						KeyValueMap[Prepend[Normal@#2,#]&,
							PacletExtensionData[pacletInfo,
								dest,
								FilterRules[{ops},
									Options@PacletExtensionData
									]
								]
							],
					Except[_List]:>
						With[{baseData=
							PacletExtensionData[pacletInfo,
								dest,
								FilterRules[{ops},
									Options@PacletExtensionData
									]
								]},
							Map[
								Replace[OptionValue[#],{
									Automatic:>
										Replace[Lookup[baseData,#],{
											a_Association:>
												Flatten@{#,Normal@a},
											_->Nothing
											}],
									r:_Rule|{___Rule}|_Association:>
										Flatten@{
											#,
											Normal@r
											},
									_->Nothing
									}]&,
								Keys@Options[PacletExtensionData]
								]
						]
					}],
			"Version"->
				Replace[OptionValue@"Version",
					Automatic:>
						With[{pointVersions=
							StringSplit[
								ToString[Lookup[pacletInfo,"Version","1.0.-1"]],
								"."
								]
							},
							StringJoin@Riffle[
								If[Length@pointVersions>1,
									Append[Most@pointVersions,
										ToString[ToExpression[Last@pointVersions]+1]
										],
									{pointVersions,"1"}],
								"."]
							]
					],
				Sequence@@Normal@pacletInfo
			]
		];


Options[PacletExpressionBundle]=
	Options[PacletExpression];
PacletExpressionBundle[paclet,dest]~~`Package`addUsage~~
	"bundles paclet into a PacletInfo.m file in dest";
PacletExpressionBundle[
	paclet_PacletManager`Paclet,
	dest_String?DirectoryQ]:=
	With[{pacletFile=FileNameJoin@{dest,"PacletInfo.m"}},
		Begin["PacletManager`"];
		Block[{$ContextPath={"System`","PacletManager`"}},
			With[{pac=
				Replace[paclet,
					(n_->v_):>(ToExpression[n]->v),
					1]},
				Export[pacletFile,pac]
				]
			];
		End[];
		pacletFile
		];
PacletExpressionBundle[
	dest_String?DirectoryQ,
	ops:OptionsPattern[]
	]:=
	PacletExpressionBundle[
		PacletExpression[dest,ops],
		dest
		];


PacletLookup[p:{__PacletManager`Paclet},props_]:=
	Lookup[PacletManager`PacletInformation/@p,props];
PacletLookup[p_PacletManager`Paclet,props_]:=
	Lookup[PacletManager`PacletInformation@p,props];
PacletLookup[p:_String|{_String,_String},props_]:=
	PacletLookup[PacletManager`PacletFind[p],props];


PacletOpen[p_,which:_:First]:=
	With[{locs=PacletLookup[p,"Location"]},
		With[{files=
			Flatten@{
				Replace[
					which@Flatten@{locs},
					HoldPattern[which[f_]]:>f
					]
				}
			},
			Map[SystemOpen,files];
			files
			]/;
			AllTrue[Flatten@{locs},StringQ]
		];


(* ::Subsection:: *)
(*Sites*)



Options[PacletSiteURL]={
	"ServerBase"->CloudDirectory,
	"ServerName"->Automatic,
	"ServerExtension"->Automatic,
	"Username"->Automatic,
	CloudConnect->False
	};
PacletSiteURL::nowid="$WolframID isn't a string. Try cloud connecting";
PacletSiteURL[ops:OptionsPattern[]]:=
	Catch@
		With[{ext=
			Replace[OptionValue["ServerExtension"],{
				Automatic->
					$PacletExtension,
				None->
					Nothing
				}]
			},
			Switch[OptionValue["ServerBase"],
				CloudObject|CloudDirectory,
					Replace[OptionValue@CloudConnect,{
						s_String:>
							If[$WolframID=!=s,
								CloudConnect[s]
								],
						{s_String,p_String}:>
							If[$WolframID=!=s,
								CloudConnect[s,p]
								],
						{s_String,e___,CloudBase->b_,r___}:>
							If[$CloudBase=!=b||$WolframID=!=s,
								CloudConnect[s,e,CloudBase->b,r]
								]
						}];
					If[!StringQ[$WolframUUID],CloudConnect[]];
					If[!StringQ[$WolframUUID],
						Message[PacletSiteURL::nowid];
						Throw@$Failed
						];
					URLBuild@
						<|
							"Scheme"->"http",
							"Domain"->"www.wolframcloud.com",
							"Path"->{
								"objects",
								Replace[OptionValue["Username"],
									Automatic->("user-"<>$WolframUUID)
									],
								ext,
								Replace[OptionValue["ServerName"],{
									e:Except[_String]:>(Nothing)
									}]
								}
							|>,
				_CloudObject|_CloudDirectory,
					With[{o=First@OptionValue["ServerBase"]},
						URLBuild@{
							o,
							ext,
								Replace[OptionValue["ServerName"],{
									e:Except[_String]:>(Nothing)
									}]
							}
						],
				_String?(StringMatchQ[FileNameJoin@{$RootDirectory,"*"}]),
					"file://"<>
						URLBuild@Key["Path"]@URLParse@
							URLBuild@
								{
									OptionValue["ServerBase"],
									ext,
									Replace[OptionValue["ServerName"],{
										Except[_String]->Nothing
										}]
									}//StringReplace[URLDecode[#]," "->"%20"]&,
				_?SyncPathQ,
					"file://"<>
						URLBuild@Key["Path"]@URLParse@
							URLBuild@Join[{
								SyncPath[
									Replace[
										StringSplit[OptionValue["ServerBase"],
											":",2],{
										{r_,p_}:>
											StringJoin@{r,":",
												URLBuild@{
													$SyncPathExtension,
													ext,
													p}
												},
										{r_}:>
											StringJoin@{r,":",
												URLBuild@{
													$SyncPathExtension,
													ext
													}
												}
										}]
									],
								Replace[OptionValue["ServerName"],{
									Except[_String]->Nothing
									}]
								}]//StringReplace[URLDecode[#]," "->"%20"]&,
				_,
					$Failed
				]
			];


Options[PacletSiteFiles]=
	Join[{
		"MergePacletInfo"->Automatic
		},
		Options@PacletSiteURL
		];
pacletFilePatterns=
	(_String|_URL|_File|_PacletManager`Paclet)|
		(
			(_String|_PacletManager`Paclet)->
				(_String|_URL|_File|_PacletManager`Paclet)
			);
PacletSiteFiles[infoFiles_,ops:OptionsPattern[]]:=
	DeleteCases[Except[pacletFilePatterns]]@
		Replace[
			Replace[
				Flatten@{infoFiles,OptionValue["MergePacletInfo"]},{
					(p_PacletManager`Paclet->_):>
						p,
					(_->f_):>f
					},
				1
				],{
			s_String?DirectoryQ:>
				Which[
					FileExistsQ@FileNameJoin@{s,"PacletSite.mz"},
						FileNameJoin@{s,"PacletSite.mz"},
					FileExistsQ@FileNameJoin@{s,"PacletInfo.m"},
						FileNameJoin@{s,"PacletInfo.m"},
					True,
						Replace[FileNames["*PacletSite.mz",s],{
							{}:>
								FileNames["*PacletInfo.m",s]
							}]
					],
			s_String?(
				MatchQ[Lookup[URLParse[#],{"Scheme","Domain","Path"}]&,
					{_String,None,{__,_?(StringMatchQ[Except["."]..])}}
					]
				):>
				StringReplace[URLBuild@{s,"PacletSite.mz"},
					StartOfString~~"file:"->
						"file://"
					],
			s_String?(
				MatchQ[Lookup[URLParse[#],{"Scheme","Domain","Path"}]&,
					{None,None,{_?(StringMatchQ[Except["."]..])}}
					]):>
				StringReplace[
					URLBuild@{
						PacletSiteURL[
							"ServerName"->s,
							FilterRules[{ops},Options@PacletSiteURL]
							],
						"PacletSite.mz"
						},{
					StartOfString~~"file:"->"file://",
					"%20"->" "
					}]
			},
			1];


pacletSiteMExtract[mzFile_,dirExt_:Automatic]:=
	With[{dir=CreateDirectory[]},
		Replace[
			Quiet[ExtractArchive[mzFile,dir,"PacletSite.m"],ExtractArchive::infer],
			Except[{__}]:>
				Quiet[
					ExtractArchive[mzFile,dir,"*/PacletInfo.m"],
					ExtractArchive::infer
					]
			]
		]


Options[PacletSiteInfo]=
	Options[PacletSiteFiles];
(*PacletSiteInfo[specs]~~`Package`addUsage~~
	"extracts the PacletSite info stored in specs";*)
PacletSiteInfo[infoFiles_,ops:OptionsPattern[]]:=
	With[{
		pacletInfos=
			Which[
				MatchQ[#,_PacletManager`Paclet],
					#,
				StringMatchQ[Replace[#,File[f_]|URL[f_]:>f],"file://*"],
					With[{f=FileNameJoin@URLParse[#]["Path"]},
						Which[
							FileExtension[f]=="mz",
								pacletSiteMExtract[f],
							True,
								f
							]
						],
				FileExistsQ@#,
					Which[
						MatchQ[FileExtension[#],"mz"|"paclet"|"tmp"],
							pacletSiteMExtract[#],
						True,
							#
						],
				URLParse[#,"Scheme"]=!=None,
					If[
						StringMatchQ[Last@URLParse[#,"Path"],
							"*.paclet"|"PacletSite.m"|
							"PacletInfo.m"|"PacletSite.mz"],
						With[{file=
							FileNameJoin@{
								$TemporaryDirectory,
								Last@URLParse[#,"Path"]
								}},
							If[Between[URLSave[#,file,"StatusCode"],{200,299}],
								Which[
									StringMatchQ[FileExtension[file],"m"|"wl"],
										file,
									StringMatchQ[FileExtension[file],"mz"|"paclet"|"tmp"],
										pacletSiteMExtract[file],
									True,
										Nothing
									],
								Nothing
								]
							],
						With[{ext=StringJoin@RandomSample[Alphabet[],5]},
							Quiet@CreateDirectory@
								FileNameJoin@{
									$TemporaryDirectory,
									ext
									};
							With[{
								file=
									FileNameJoin@{
										$TemporaryDirectory,
										ext,
										"PacletSite.mz"
										}
								},
								If[
									Between[
										URLSave[URLBuild@{#,"PacletSite.mz"},file,"StatusCode"],
										{200,299}
										],
									pacletSiteMExtract[file,ext],
									Nothing
									]
								]
							]
						],
					True,
					Nothing
				]&/@PacletSiteFiles[infoFiles,ops]//Flatten
		},
		Begin["PacletManager`"];
		With[{pacletsite=
			PacletManager`PacletSite@@
				Flatten@
					Map[
						With[{imp=
							Replace[If[MatchQ[#,(_String|_File)?FileExistsQ],Import[#],#],
								{
									PacletManager`PacletSite[p___]:>p,
									e:Except[_PacletManager`Paclet|{__PacletManager`Paclet}]:>
										(Nothing)
									}
								]
							},
							Replace[#,
								(s_Symbol->v_):>(SymbolName[s]->v),
								1]&/@Flatten@{imp}
							]&,
						pacletInfos
						]//DeleteDuplicates
			},
			End[];
			DeleteCases[pacletsite,Except[_PacletManager`Paclet]]
			]
		];


PacletSiteInfoDataset::usages="";


PacletSiteInfoDataset[site]~`Package`addUsage~
	"formats a Dataset from the PacletInfo in site";
PacletSiteInfoDataset[files]~`Package`addUsage~
	"formats from the PacletSiteInfo in files";


Options[PacletSiteInfoDataset]=
	Options[PacletSiteInfo];
PacletSiteInfoDataset[PacletManager`PacletSite[p___]]:=
	Dataset@Map[PacletInfoAssociation,{p}];
PacletSiteInfoDataset[files__,ops:OptionsPattern[]]:=
	PacletSiteInfoDataset[PacletSiteInfo[files,ops]];


Options[PacletSiteBundle]=
	Join[{
		"BuildRoot":>$TemporaryDirectory,
		"FilePrefix"->None
		},
		Options@PacletSiteInfo
		];
PacletSiteBundle[infoFiles]~~`Package`addUsage~~
	"bundles the PacletInfo.m files found in infoFiles into a compressed PacletSite file";
PacletSiteBundle[
	infoFiles:pacletFilePatterns|{pacletFilePatterns...},
	ops:OptionsPattern[]]:=
	Export[
		FileNameJoin@{
			With[{d=
				FileNameJoin@{
					OptionValue["BuildRoot"],
					$PacletBuildExtension
					}
				},
				If[!FileExistsQ@d,
					CreateDirectory@d
					];
				d
				],
			Replace[OptionValue["FilePrefix"],{
				Automatic:>
					With[{f=First@{infoFiles}},
						If[StringMatchQ[FileNameTake[f],"*.*"],
							DirectoryName[f],
							FileBaseName[f]
							]
						]<>"-",
				s_String:>(s<>"-"),
				_->""
				}]<>"PacletSite.mz"
			},
		PacletSiteInfo[infoFiles,
			FilterRules[{ops},
				Options@PacletSiteInfo
				]
			],
		{"ZIP", "PacletSite.m"}
		];


PacletBundle[dir]~`Package`addUsage~
	"creates a .paclet file from dir and places it in the default build directory";
Options[PacletBundle]={
	"RemovePaths"->{},
	"RemovePatterns"->".DS_Store",
	"BuildRoot":>$PacletBuildRoot
	};
PacletBundle[dir:(_String|_File)?DirectoryQ,ops:OptionsPattern[]]:=
	With[{pacletDir=
			FileNameJoin@{
				OptionValue["BuildRoot"],
				$PacletBuildExtension,
				FileBaseName@dir
				}
			},
		If[!FileExistsQ@DirectoryName[pacletDir],
			CreateDirectory@DirectoryName[pacletDir]
			];
		If[FileExistsQ@pacletDir,
			DeleteDirectory[pacletDir,DeleteContents->True]
			];
		CopyDirectory[dir,pacletDir];
		Do[
			With[{p=If[Not@FileExistsQ@path,FileNameJoin@{pacletDir,path},path]},
				If[DirectoryQ@p,
					DeleteDirectory[p,
						DeleteContents->True
						],
					If[FileExistsQ@p,DeleteFile[p]]
					]
				],
			{path,
				Join[
					Flatten[{OptionValue["RemovePaths"]},1],
					FileNameDrop[#,FileNameDepth@pacletDir]&/@
						FileNames[OptionValue["RemovePatterns"],pacletDir,\[Infinity]]
					]}
			];
		With[{pacletFile=PacletManager`PackPaclet[pacletDir]},
			pacletFile
			]
		];


(* ::Subsection:: *)
(*Installers*)



Options[PacletInstallerURL]=
	Options@PacletSiteURL;
PacletInstallerURL[ops:OptionsPattern[]]:=
	StringReplace[
		URLBuild@{PacletSiteURL[ops],"Installer.m"},
		StartOfString~~"file:"->"file://"
		];


Options[PacletInstallerScript]:=
	DeleteDuplicatesBy[First]@
		Join[
			Options@PacletInstallerURL,{
			"InstallSite"->
				False,
			"PacletSite"->
				Automatic,
			"PacletNames"->
				Automatic,
			"PacletSiteFile"->
				Automatic
			}
			];
PacletInstallerScript[ops:OptionsPattern[]]:=
	Module[{
		ps=
			Replace[OptionValue["PacletSite"],
				Automatic:>
					With[{p=
						PacletSiteURL@
							FilterRules[{ops},Options@PacletSiteURL]
						},
						If[URLParse[p,"Scheme"]==="file",
							FileNameJoin@URLParse[p,"Path"],
							p
							]
						]
				],
		info=
			Normal@PacletSiteInfoDataset@
				Replace[OptionValue@"PacletSiteFile",
					Except[(_File|_String)?FileExistsQ]:>
						Replace[OptionValue["PacletSite"],
							Automatic:>
								StringReplace[
									URLBuild@{
										PacletSiteURL@
											FilterRules[{ops},
												Options@PacletSiteURL],
										"PacletSite.mz"
										},
									StartOfString~~"file:"->"file://"
									]
						]
					],
		names
		},
		names=
			DeleteMissing@
				Replace[OptionValue["PacletNames"],
					Automatic:>
						Lookup[info,{"Name","Version"}]
					];
			Which[StringMatchQ[ps,"http:*"|"https:*"|"file:*"],
				If[OptionValue@"InstallSite"//TrueQ,
					With[{
						desc=
							"Paclet Server for: "<>
								StringRiffle[First/@Replace[names,s_String:>{s},1],", "],
						site=ps,
						paclets=names
						},
						Hold[
							PacletManager`PacletSiteAdd[site,
								desc,
								Prepend->True
								];
							PacletManager`PacletInstall[#,
								"Site"->site
								]&/@paclets
							]
						],
					With[{
						pacletFiles=
							URLBuild@{
								ps,
								"Paclets",
								#[["Name"]]<>"-"<>#[["Version"]]<>".paclet"
								}&/@info
						},
						Hold[
							With[{file=
								FileNameJoin@{
									$TemporaryDirectory,
									URLParse[#,"Path"]//Last
									}
								},
								If[Between[URLSave[#,file,"StatusCode"],{200,299}],
									PacletManager`PacletInstall@file,
									$Failed
									]
								]&/@pacletFiles
							]
						]
					],
				StringMatchQ[ps,
					($UserBaseDirectory|$HomeDirectory|
						$BaseDirectory|$InstallationDirectory|$RootDirectory)
						~~___],
					Replace[
						Replace[
							SelectFirst[
								Thread@Hold[{
									$UserBaseDirectory,$HomeDirectory,
										$BaseDirectory,$InstallationDirectory,
										$RootDirectory}],
								StringMatchQ[ps,ReleaseHold[#]~~__]&
								],
							Hold[p_]:>
								Replace[FileNameSplit[StringTrim[ps,p]],{
									{"",s__}:>
										Hold[{p,s}],
									{s__}:>
										Hold[p,s]
									}]
							],{
						Hold[fp_]:>
							If[OptionValue@"InstallSite",
								With[{desc=
									"Paclet Server for: "<>
										Riffle[names," "]
									},
									Hold[
										PacletManager`PacletSiteAdd[
											"file://"<>URLBuild@fp,
											desc,
											Prepend->True
											];
										If[$VersionNumber<11.2,
										   PacletManager`Services`Private`finishPacletSiteUpdate[
										   	{
										   		PacletManager`Private`siteURL_, 
										   		PacletManager`Private`file_, 
										   		PacletManager`Private`interactive_, 
										   		PacletManager`Private`async_, 
										   		0}
										   	] := 
										   	PacletManager`Services`Private`finishPacletSiteUpdate[
										   		{
															PacletManager`Private`siteURL, 
															PacletManager`Private`file, 
															PacletManager`Private`interactive, 
															PacletManager`Private`async, 
															200}
										   		];
										   PacletManager`Package`getTaskData[task_] := 
										   	Block[{PacletManager`Private`$inTaskDataPatch = True}, 
										   		Replace[PacletManager`Package`getTaskData[task], 
										   			{
										   				PacletManager`Private`a_, 
										   				PacletManager`Private`b_, 
										   				PacletManager`Private`c_, 
										   				PacletManager`Private`d_, 
										   				PacletManager`Private`e_, 0, 
										   				PacletManager`Private`rest__} :> 
										   				{
										   					PacletManager`Private`a, 
										   					PacletManager`Private`b, 
										   					PacletManager`Private`c, 
										   					PacletManager`Private`d, 
										   					PacletManager`Private`e, 200, 
										   					PacletManager`Private`rest}]
										   		] /; ! TrueQ[PacletManager`Private`$inTaskDataPatch]
										   	];
									   PacletManager`PacletInstall[
											#,
											"Site"->("file://"<>URLBuild@fp),
											"Asynchronous"->False
											]&/@names
										]
									],
								With[{paclets=
									StringReplace[
										URLBuild@{
											ps,
											"Paclets",
											#[["Name"]]<>"-"<>#[["Version"]]<>".paclet"
											}&/@info,
										"file:"->"file://"
										]
									},
									Hold[
										If[FileExistsQ@#,
											PacletManager`PacletInstall@#,
											$Failed
											]&/@paclets
										]
									]
								]
						}],
				True,
					$Failed
				]
		];
PacletInstallerScript[
	ps_,
	names:{__String}|Automatic:Automatic,
	ops:OptionsPattern[]]:=
	PacletInstallerScript[
		"PacletSite"->ps,
		"PacletNames"->names,
		ops
		]


Options[PacletUploadInstaller]:=
	DeleteDuplicatesBy[First]@
		Join[
			Options@PacletInstallerScript,{
			Permissions->"Public"
			},
			Options@CloudExport
			];
PacletUploadInstaller[ops:OptionsPattern[]]:=
	With[{
		installerLoc=
			With[{p=
				PacletInstallerURL@
					FilterRules[{ops},Options@PacletInstallerURL]
				},
				If[URLParse[p,"Scheme"]==="file",
					FileNameJoin@URLParse[p,"Path"],
					p
					]
				],
		script=
			PacletInstallerScript@
				FilterRules[{ops},
					Options@PacletInstallerScript
					]
		},
			Which[
				StringMatchQ[installerLoc,"http:*"|"https:*"],
					(SetOptions[
						CopyFile[#,#,
							"MIMEType"->"application/vnd.wolfram.mathematica.package"
							],
						FilterRules[{ops},
							Options@CloudExport
							]
						];#)&@
						Replace[script,
							Hold[s_]:>
								CloudPut[Unevaluated[s],
									installerLoc
									]
							],
					True,
						If[Not@FileExistsQ@installerLoc,
							CreateFile[installerLoc,
								CreateIntermediateDirectories->True
								]
							];
							Replace[script,
								Hold[s_]:>
									Put[Unevaluated[s],
										installerLoc
										]
								];
						installerLoc
				]
		]


Options[PacletUninstallerURL]=
	Options@PacletSiteURL;
PacletUninstallerURL[ops:OptionsPattern[]]:=
	StringReplace[
		URLBuild@{PacletSiteURL[ops],"Uninstaller.m"},
		StartOfString~~"file:"->"file://"
		];


Options[PacletUninstallerScript]:=
	DeleteDuplicatesBy[First]@
		Join[
			Options@PacletUninstallerURL,{
			"UninstallSite"->
				False,
			"PacletSite"->Automatic,
			"PacletNames"->Automatic,
			"PacletSiteFile"->Automatic
			}
			];
PacletUninstallerScript[ops:OptionsPattern[]]:=
	Module[{
		ps=
			Replace[OptionValue["PacletSite"],
				Automatic:>
					With[{p=
						PacletSiteURL@
							FilterRules[{ops},Options@PacletSiteURL]
						},
						If[URLParse[p,"Scheme"]==="file",
							FileNameJoin@URLParse[p,"Path"],
							p
							]
						]
				],
		info=
			Normal@PacletSiteInfoDataset@
				Replace[OptionValue@"PacletSiteFile",
					Except[(_File|_String)?FileExistsQ]:>
						Replace[OptionValue["PacletSite"],
							Automatic:>
								StringReplace[
									URLBuild@{
										PacletSiteURL@
											FilterRules[{ops},
												Options@PacletSiteURL],
										"PacletSite.mz"
										},
									StartOfString~~"file:"->"file://"
									]
						]
					],
		names
		},
		names=
			DeleteMissing@
				Replace[OptionValue["PacletNames"],
					Automatic:>
						Lookup[info,{"Name","Version"}]
					];
			Which[StringMatchQ[ps,"http:*"|"https:*"(*|"file:*"*)],
				With[{
						site=
							ps,
						paclets=
							names
						},
					If[OptionValue["UninstallSite"],
						Hold[
							PacletManager`PacletSiteRemove[site];
							PacletManager`PacletUninstall[#]&/@paclets
							],
						Hold[PacletManager`PacletUninstall[#]&/@paclets]
						]
					],
				StringMatchQ[ps,
					($UserBaseDirectory|$HomeDirectory|
						$BaseDirectory|$InstallationDirectory|$RootDirectory)
						~~___],
					Replace[
						Replace[
							SelectFirst[
								Thread@Hold[{
									$UserBaseDirectory,$HomeDirectory,
										$BaseDirectory,$InstallationDirectory,
										$RootDirectory}],
								StringMatchQ[ps,ReleaseHold[#]~~__]&
								],
							Hold[p_]:>
								Replace[FileNameSplit[StringTrim[ps,p]],{
									{"",s__}:>
										Hold[{p,s}],
									{s__}:>
										Hold[p,s]
									}]
							],{
						Hold[fp_]:>
							With[{
								site=ps,
								paclets=names
								},
								If[OptionValue@"UninstallSite",
									Hold[
										PacletManager`PacletSiteRemove@
											("file://"<>URLBuild@fp);
										PacletManager`PacletUninstall[#]&/@names;
										names
										],
									Hold[
										PacletManager`PacletUninstall[#]&/@paclets;
										names
										]
									]
								]
					}],
				True,
					$Failed
				]
		];
PacletUninstallerScript[
	ps_,
	names:{__String}|Automatic:Automatic,
	ops:OptionsPattern[]]:=
	PacletUninstallerScript[
		"PacletSite"->ps,
		"PacletNames"->names,
		ops
		]


Options[PacletUploadUninstaller]:=
	DeleteDuplicatesBy[First]@
		Join[
			Options@PacletUninstallerScript,{
			Permissions->"Public"
			},
			Options@CloudExport
			];
PacletUploadUninstaller[ops:OptionsPattern[]]:=
	With[{
		installerLoc=
			With[{p=
				PacletUninstallerURL@
					FilterRules[{ops},Options@PacletUninstallerURL]
				},
				If[URLParse[p,"Scheme"]==="file",
					FileNameJoin@URLParse[p,"Path"],
					p
					]
				],
		script=
			PacletUninstallerScript@
				FilterRules[{ops},
					Options@PacletUninstallerScript
					]
		},
			Which[
				StringMatchQ[installerLoc,"http:*"|"https:*"],
					(SetOptions[
						CopyFile[#,#,
							"MIMEType"->"application/vnd.wolfram.mathematica.package"
							],
						FilterRules[{ops},
							Options@CloudExport
							]
						];#)&@
						Replace[script,
							Hold[s_]:>
								CloudPut[Unevaluated[s],
									installerLoc
									]
							],
					True,
						If[Not@FileExistsQ@installerLoc,
							CreateFile[installerLoc,
								CreateIntermediateDirectories->True
								]
							];
							Replace[script,
								Hold[s_]:>
									Put[Unevaluated[s],
										installerLoc
										]
								];
						installerLoc
				]
		]


(* ::Subsection:: *)
(*Upload*)



$PacletAPIUploadAPIs=
	{
		"GoogleDrive"|"Google Drive"|"googledrive"|"google drive"->
			"GoogleDrive"
		};
PacletAPIUploadAPIQ[s_String]:=
	MatchQ[PacletAPIUploadAPIQ,Alternatives@@Keys@$PacletAPIUploadAPIs]


PacletAPIUpload[
	pacletFile:(_String|_File)?(Not@DirectoryQ@#&&FileExtension[#]==="paclet"&),
	apiName_:"GoogleDrive"
	]:=
	With[{api=apiName/.$PacletAPIUploadAPIs},
		With[{pac=pacletAPIUpload[pacletFile,api]},
			Replace[pac,
				url_String:>
					(PacletInfo[pacletFile]->url)
				]/;!MatchQ[pac,_pacletAPIUpload]
			]
		];


pacletAPIUpload[pacletFile_,"GoogleDrive"]:=
	With[{fil=GoogleDrive["Upload",pacletFile]},
		GoogleDrive["Publish",fil];
		Replace[#["WebContentLink"],URL[u_]:>u]&@
			GoogleDrive["Info",fil,{"name","webContentLink"}]
		]


urlBasedPacletQ[url_String]:=
	With[{data=URLParse[url]},
		(
			data["Domain"]==="drive.google.com"
			&&
			MemberQ[data["Query"],"export"->"download"]
			)
			||
			(
				data["Scheme"]=!=None&&
					FileExtension@Last@data["Path"]==="paclet"
				)
		];


urlBasedPacletRedirect[site_]:=
	URLParse[site,"Path"][[-1]]->HTTPRedirect[site];


builtPacletFileFind[
	f:_PacletManager`Paclet|_String|_URL|_File|
	{f_String,v_String}
	]:=
		Which[
			MatchQ[f,_PacletManager`Paclet],
				With[{
					info=
						Lookup[
							PacletManager`PacletInformation@f,
							{"Location","Name","Version"}
							]},
					If[FileExistsQ@(info[[1]]<>".paclet"),
						info[[1]]<>".paclet",
						Replace[builtPacletFileFind@info[[2;;3]],
							None:>
								If[DirectoryQ@info[[1]],
									PacletBundle[info[[1]]],
									None
									]
							]
						]
					],
			MatchQ[f,(_String|_URL)?urlBasedPacletQ],
				First@Flatten[URL[f],1,URL],
			True,
			Replace[{
				File[fil_]:>fil
				}]@
				SelectFirst[
					{
						If[DirectoryQ@f,
							If[FileExistsQ@FileNameJoin@{f,"PacletInfo.m"},
								With[{a=PacletInfoAssociation[FileNameJoin@{f,"PacletInfo.m"}]},
									Replace[builtPacletFileFind@Lookup[a,{"Name","Version"}],
										None:>
											PacletBundle[f]
										]
									],
								Nothing
								],
							f
							],
						FileNameJoin@{
							$PacletBuildRoot,
							$PacletBuildExtension,
							f<>"-"<>v<>".paclet"
							},
						FileNameJoin@{
							$PacletBuildRoot,
							$PacletBuildExtension,
							StringTrim[f,".paclet"]<>".paclet"
							}
					},
					FileExistsQ,
					None
					]
			];
builtPacletFileFind[Rule[s_,p_]]:=
	Rule[s,builtPacletFileFind[p]]
builtPacletFileQ[spec_]:=
	!MatchQ[builtPacletFileFind[spec],None|Labeled[None,_]];


pacletSpecPattern=
	(_String|_URL|_File|{_String,_String}|_PacletManager`Paclet)|
		Rule[
			_String|_PacletManager`Paclet,
			(_String|_URL|_File|{_String,_String}|_PacletManager`Paclet)
			];
pacletPossiblePatterns=
	pacletSpecPattern|{pacletSpecPattern..}


Options[PacletUpload]=
	DeleteDuplicatesBy[First]@
		Join[
			Options[PacletSiteURL],
			{
				"BuildRoot":>$PacletBuildRoot,
				"SiteFile"->Automatic,
				"OverwriteSiteFile"->False,
				"UploadSiteFile"->False,
				"UploadInstaller"->False,
				"UploadUninstaller"->False,
				Permissions->"Public"
				}
			];
PacletUpload::nopac="Unable to find paclet files ``";
PacletUpload[pacletFiles]~~`Package`addUsage~~
	"uploads pacletFiles to the specified server and configures installers";
PacletUpload[
	pacletSpecs:pacletPossiblePatterns,
	ops:OptionsPattern[]
	]:=
	Block[{
		$PacletBuildRoot=OptionValue["BuildRoot"],
		files
		},
		files=builtPacletFileFind/@Flatten@{pacletSpecs};
		If[!AllTrue[files,builtPacletFileQ],
			Message[PacletUpload::nopac,
				Pick[Flatten@{pacletSpecs},MatchQ[None|Labeled[None,_]]/@files]
				]
			];
		pacletUpload[pacletSpecs,ops]/;
			AllTrue[files,builtPacletFileQ]
		];


Options[pacletUpload]=
	Options@PacletUpload;
pacletUpload[
	pacletSpecs:pacletPossiblePatterns,
	ops:OptionsPattern[]
	]:=
	Catch@
		DeleteCases[Nothing]@
		With[{
			site=
				PacletSiteURL[
					FilterRules[{
						ops,
						"ServerName"->
							Replace[Flatten@{pacletSpecs},{
								{p_PacletManager`Paclet->_,___}:>
									Lookup[List@@p,"Name"],
								{s_String->_,___}:>
									First@StringSplit[URLParse[s,"Path"][[-1]],"-"],
								{f_String?FileExistsQ,___}:>
									First@StringSplit[FileBaseName@f,"-"],
								{p_String,___}:>
									First@StringSplit[URLParse[p,"Path"][[-1]],"-"],
								{p_PacletManager`Paclet,___}:>
									Lookup[List@@p,"Name"]
								}]
						},
						Options@PacletSiteURL
						]
					],
			pacletFiles=builtPacletFileFind/@Flatten@{pacletSpecs}
			},
			If[MatchQ[site,Except[_String]],Throw@$Failed];
			With[{pacletMZ=
				If[OptionValue["UploadSiteFile"]//TrueQ,
					Replace[OptionValue["SiteFile"],
						Automatic:>
							PacletSiteBundle[
								Replace[pacletFiles,
									(k_->_):>k
									],
								FilterRules[{ops,
									"MergePacletInfo"->
										If[OptionValue["OverwriteSiteFile"]//TrueQ,None,site]
									},
									Options@PacletSiteBundle
									]
								]
						]
					]},
				Switch[OptionValue["ServerBase"],
					(* ------------------- Wolfram Cloud Paclets ------------------- *)
					CloudObject|CloudDirectory|Automatic,
						With[{url=site},
							<|
								"PacletSiteFile"->
									If[MatchQ[pacletMZ,(_String|_File)?FileExistsQ],
										Most@
											CopyFile[pacletMZ,
												CloudObject[
													URLBuild@{url,"PacletSite.mz"},
													Permissions->OptionValue@Permissions
													]
												],
										Nothing
										],
								"PacletFiles"->
									Map[
										With[{
											co=
												CloudObject[
													URLBuild@{
														url,
														"Paclets",
														Replace[#,{
															Rule[n_PacletManager`Paclet,_]:>
																StringJoin@
																	Riffle[
																		Lookup[List@@n,{"Name","Version"}],
																		{"-",".paclet"}
																		],
															Rule[n_String,_]:>
																n,
															URL[u_]:>
																URLParse[u,"Path"][[-1]],
															_:>
																If[FileExistsQ@#,
																	FileNameTake@#,
																	URLParse[#,"Path"][[-1]]
																	]
															}]
														},
													Permissions->OptionValue@Permissions
													],
											fil=
												Replace[#,
													Rule[_,f_]:>f
													]
											},
											Most@
												If[
													Switch[#,
														_File|_String,
															FileExistsQ@#,
														_URL,
															False,
														_Rule,
															FileExistsQ@Last@#
														],
													CopyFile[
														If[MatchQ[#,_Rule],Last@#,#],
														co],
													CloudDeploy[
														HTTPRedirect@
															If[MatchQ[#,_Rule],
																Last@#,
																#],
														co]
													]
											]&,
										pacletFiles
										],
								"PacletInstaller"->
									If[OptionValue["UploadInstaller"],
										PacletUploadInstaller[ops,
											Permissions->
												OptionValue@Permissions,
											"PacletSiteFile"->
												pacletMZ
											],
										Nothing
										],
								"PacletUninstaller"->
									If[OptionValue["UploadUninstaller"],
										PacletUploadUninstaller[ops,
											Permissions->
												OptionValue@Permissions,
											"PacletSiteFile"->
												pacletMZ
											],
										Nothing
										]
								|>	
							],
					(* ------------------- Local Paclets ------------------- *)
					_String?(StringMatchQ[FileNameJoin@{$RootDirectory,"*"}]),
						With[{dir=URLDecode@StringTrim[site,"file://"]},
							If[Not@DirectoryQ@dir,
								CreateDirectory[dir,
									CreateIntermediateDirectories->True
									]
								];
							<|
								"PacletSite"->
									If[MatchQ[pacletMZ,(_String|_File)?FileExistsQ],
										CopyFile[pacletMZ,
											FileNameJoin@{dir,"PacletSite.mz"},
											OverwriteTarget->True
											],
										Nothing
										],
								"PacletFiles"->
									Map[
										(
											Quiet@
												CreateFile[
													FileNameJoin@{dir,"Paclets",FileNameTake@#}
													];
											CopyFile[#,
												FileNameJoin@{dir,"Paclets",FileNameTake@#},
												OverwriteTarget->True
												]
											)&,
										pacletFiles
										],
								"PacletInstaller"->
									If[OptionValue["UploadInstaller"],
										PacletUploadInstaller@
											FilterRules[{ops},
												Options@PacletUploadInstaller
												],
										Nothing
										],
								"PacletUninstaller"->
									If[OptionValue["UploadUninstaller"],
										PacletUploadUninstaller@
											FilterRules[{ops},
												Options@PacletUploadUninstaller
												],
										Nothing
										]
								|>	
							],
					_?SyncPathQ,
						With[{p=SyncPath@OptionValue["ServerBase"]},
							Quiet@CreateDirectory[p,
								CreateIntermediateDirectories->True];
							PacletUpload[
								pacletFiles,
								"ServerBase"->p,
								ops
								]
							],
					_,
						$Failed
						]
				]
			];


Options[PacletSiteInstall]=
	Options@PacletSiteURL;
PacletSiteInstall[site_String]:=
	Which[
		DirectoryQ@site,
			If[FileExistsQ@FileNameJoin@{site,"Installer.m"},
				Get@FileNameJoin@{site,"Installer.m"},
				PacletInstallerScript[site]//ReleaseHold
				],
		StringMatchQ[site,"file:*"],
			With[{f=FileNameJoin@URLParse[site,"Path"]},
				If[DirectoryQ@f,
					If[FileExistsQ@FileNameJoin@{f,"Installer.m"},
						Get@FileNameJoin@{f,"Installer.m"},
						PacletInstallerScript[f]//ReleaseHold
						],
					$Failed
					]
				],
		StringMatchQ[site,"http:*"|"https:*"],
			With[{f=URLBuild@{site,"Installer.m"}},
				If[Between[URLRead[f,"StatusCode"],{200,299}],
					CloudGet@f,
					If[Quiet@Get[f]===$Failed,
						PacletInstallerScript[site]//ReleaseHold
						]
					]
				],
		True,
			$Failed
		];
PacletSiteInstall[ops:OptionsPattern[]]:=
	PacletSiteInstall[PacletSiteURL[ops]];


Options[PacletSiteUninstall]=
	Options@PacletSiteURL;
PacletSiteUninstall[site_String]:=
	Which[
		DirectoryQ@site,
			If[FileExistsQ@FileNameJoin@{site,"Uninstaller.m"},
				Get@FileNameJoin@{site,"Uninstaller.m"},
				PacletUninstallerScript[site]//ReleaseHold
				],
		StringMatchQ[site,"file:*"],
			With[{f=FileNameJoin@URLParse[site,"Path"]},
				If[DirectoryQ@f,
					If[FileExistsQ@FileNameJoin@{f,"Uninstaller.m"},
						Get@FileNameJoin@{f,"Uninstaller.m"},
						PacletUninstallerScript[f]//ReleaseHold
						],
					$Failed
					]
				],
		StringMatchQ[site,"http:*"|"https:*"],
			With[{f=URLBuild@{site,"Uninstaller.m"}},
				If[Quiet@Get[f]===$Failed,
					PacletUninstallerScript[site]//ReleaseHold
					]
				],
		True,
			$Failed
		];
PacletSiteUninstall[ops:OptionsPattern[]]:=
	PacletSiteUninstall@PacletSiteURL[ops];


(* ::Subsection:: *)
(*Servers*)



Options[PacletServerConfigure]:=
	PacletServerConfigure[]


(* ::Subsection:: *)
(*Download*)



PacletDownload[
	paclet_CloudObject,
	components:_String|{__String}:"PacletInfo.m"
	]:=
	With[{info=CloudObjectInformation[paclet,{"OwnerWolframUUID","Path"}]},
CloudEvaluate[
With[{i=
Compress@
Map[Import,Flatten@{#}]},
Map[DeleteFile,Flatten@{#}];
i
]&@
ExtractArchive[
FileNameJoin@{
$RootDirectory,
"wolframcloud",
"userfiles",
StringTake[#OwnerWolframUUID,3],
#OwnerWolframUUID,
Sequence@@Rest@URLParse[#Path,"Path"]
}&@info,
FileNameJoin@{$HomeDirectory,"trash"},
Alternatives@@Map["*"<>#&,components]
]
]
]//Uncompress


End[];




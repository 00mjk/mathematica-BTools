(* ::Package:: *)



(* ::Subsubsection::Closed:: *)
(*Settings*)



$PacletBuildRoot::usage="The root directory for building paclets";
$PacletBuildExtension::usage="The directory extension for building paclets";
$PacletBuildDirectory::usage="Joins the root and extension";
$PacletExtension::usage="The default ServerExtension";
$PacletServerBase::usage="The default ServerBase";
$PacletUseKeychain::usage="Whether to use the Keychain or not";
$FormatPaclets::usage="Specifies whether or not to use new paclet formatting";


$PacletUploadPatterns::usage=
  "Possible forms for PacletUpload";
$PacletRemovePatterns::usage=
  "Possible forms for PacletRemove";
$PacletFilePatterns::usage=
  "Possible forms for a paclet file";
$PacletUploadAccount::usage=
  "The account to which paclets get uploaded by default";


(* ::Subsubsection::Closed:: *)
(*Paclets*)



PacletInfo::usage=
  "Extracts the Paclet from a PacletInfo.m file";


PackageScopeBlock[
  PacletInfoExpressionBundle::usage=
    "Bundles a PacletInfoExpression into a PacletInfo.m file";
  ];


PacletInfoAssociation::usage=
  "Converts a Paclet into an Association";
PacletInfoExpression::usage=
  "Generates a Paclet expression for a directory";  
PacletBundle::usage=
  "Bundles a paclet site from a directory in a standard build directory";
PacletFindBuiltFile::usage=
  "Finds a built paclet file";
PacletAutoPaclet::usage=
  "Autogenerates a paclet";
PacletLookup::usage=
  "Applies Lookup to paclets";
PacletInfoGenerate::usage=
  "Generates a PacletInfo.m file from a directory";
PacletOpen::usage=
  "Opens an installed paclet from its \"Location\"";


PacletInstalledQ::usage=
  "Tests whether a paclet has been installed";


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



PackageScopeBlock[
  PacletInstallerURL::usage=
    "Provides the default URL for a paclet installer";
  PacletUploadInstaller::usage=
    "Uploads the paclet installer script";
  PacletUninstallerURL::usage=
    "Provides the default URL for a paclet installer";
  PacletUploadUninstaller::usage=
    "Uploads the paclet installer script";
  PacletSiteInstall::usage=
    "Installs from the Installer.m file if possible";
  PacletSiteUninstall::usage=
    "Uninstalls from the Uninstaller.m file if possible";,
  "Deprecated"
  ];


(* ::Subsubsection::Closed:: *)
(*Uploads*)



PacletSiteUpload::usage=
  "Uploads a PacletSite.mz file";
PacletAPIUpload::usage=
  "Creates a paclet link via an API based upload";


PacletUpload::usage=
  "Uploads a paclet to a server";
PacletRemove::usage=
  "Removes a paclet from a server";


(* ::Subsubsection::Closed:: *)
(*Install*)



PacletDownloadPaclet::usage="Downloads a paclet from a URL";
PacletInstallPaclet::usage="Installs a paclet from a URL";


(* ::Subsubsection::Closed:: *)
(*Formatting*)



SetPacletFormatting::usage="Sets new paclet formatting";


Begin["`Private`"];


(* ::Subsection:: *)
(*Config*)



$PacletBuildDirectory:=
  FileNameJoin@{$PacletBuildRoot, $PacletBuildExtension};
If[PacletExecuteSettingsLookup["ClearBuildCacheOnLoad"],
  Quiet@DeleteDirectory[$PacletBuildDirectory, DeleteContents->True];
  ];


$PacletBuildRoot:=
  PacletExecuteSettingsLookup["BuildRoot"];
$PacletBuildExtension:=
  PacletExecuteSettingsLookup["BuildExtension"];
$PacletUseKeychain:=
  PacletExecuteSettingsLookup["UseKeychain"];


$FormatPaclets:=
  PacletExecuteSettingsLookup["FormatPaclets"];


$PacletFilePatterns:=
  PacletExecuteSettingsLookup[
    "FilePattern",
    (_String|_URL|_File|_PacletManager`Paclet)|
    (
      (_String|_PacletManager`Paclet)->
        (_String|_URL|_File|_PacletManager`Paclet)
      )
    ];


$PacletSpecPattern:=
  PacletExecuteSettingsLookup[
    "UploadPattern",
    (_String|_URL|_File|{_String,_String}|_PacletManager`Paclet)|
      Rule[
        _String|_PacletManager`Paclet,
        (_String|_URL|_File|{_String,_String}|_PacletManager`Paclet)
        ]
    ];
$PacletUploadPatterns:=
  $PacletSpecPattern|{$PacletSpecPattern..}


(* ::Subsection:: *)
(*Paclets*)



(* ::Subsubsection::Closed:: *)
(*PacletInfoAssociation*)



$validPacletFields:=
  $validPacletFields=
    Keys@Options[PacletInfoExpression];
$pacletFieldMap=
  AssociationThread[
    $validPacletFields,
    Range[Length[$validPacletFields]]
    ];


makePacletInfoAssociation[PacletManager`Paclet[k__]]:=
  KeySortBy[$pacletFieldMap]@
    With[{base=
      KeyMap[Replace[s_Symbol:>SymbolName[s]],<|k|>]
      },
      ReplacePart[base,
        "Extensions"->
          AssociationThread[
            First/@Lookup[base,"Extensions",{}],
            Association@*Rest/@Lookup[base,"Extensions",{}]
            ]
        ]
      ];


Clear[validatePacletAssociationField];
validatePacletAssociationField["Location", Except[_String?DirectoryQ]]:=
  Nothing;
validatePacletAssociationField[_, ""]:=
  Nothing;
validatePacletAssociationField[k_, f_]:=
  k->f;


iPacletInfoAssociation[p:PacletManager`Paclet[k__]]:=
  Association@
    KeyValueMap[
      validatePacletAssociationField,
      makePacletInfoAssociation[p]
      ];
iPacletInfoAssociation[PacletManager`Paclet[]]:=<||>


$pacletInfoSpec=
  _String|
  {_String, _String?(StringEndsQ[NumberString])}|
  _File?FileExistsQ|
  _PacletManager`Paclet;


PacletInfoAssociation[infoFile:$pacletInfoSpec]:=
  Replace[PacletInfo[infoFile],
    {
      p:_PacletManager`Paclet:>
        iPacletInfoAssociation@p,
      p:{__PacletManager`Paclet}:>
        iPacletInfoAssociation/@p,
      _-><||>
      }
    ];
PacletInfoAssociation[l:{$pacletInfoSpec..}]:=
  PacletInfoAssociation/@l;


(* ::Subsubsection::Closed:: *)
(*PacletInfo*)



Options[PacletInfo]=
  Options[PacletManager`PacletFind];
PacletInfo[infoFile:(_String|_File)?FileExistsQ, ops:OptionsPattern[]]:=
  Block[{$tmpdir},
    With[{pacletInfo=
      Replace[infoFile,
        {
          d:(_String|_File)?DirectoryQ:>
            FileNameJoin@{d, "PacletInfo.m"},
          f:(_String|_File)?(FileExtension[#]=="paclet"&&FileExistsQ[#]&):>
            With[{rd=$tmpdir=CreateDirectory[]},
              First@ExtractArchive[f,rd,"*PacletInfo.m"]
              ]
          }
        ]
      },
      (
        If[StringQ[$tmpdir], DeleteDirectory[$tmpdir, DeleteContents->True]];
        #
        )&@
      If[FileExistsQ@pacletInfo,
        PacletManager`CreatePaclet[pacletInfo],
        PacletManager`Paclet[]
        ]
      ]
    ];
PacletInfo[pac_PacletManager`Paclet, ops:OptionsPattern[]]:=
  pac;(*With[{pf=pac["Location"]},
		If[StringQ@pf&&FileExistsQ@FileNameJoin@{pf, "PacletInfo.m"},
			PacletInfo@FileNameJoin@{pf, "PacletInfo.m"},
			pac
			]
		];*)
PacletInfo[
  p:_String|{_String, _String?(StringEndsQ[NumberString])}, 
  ops:OptionsPattern[]
  ]:=
  (*PacletInfo@*)PacletManager`PacletFind[p, ops];
PacletInfo[l:{$pacletInfoSpec..}, ops:OptionsPattern[]]:=
  PacletInfo[#, ops]&/@l;


(* ::Subsubsection::Closed:: *)
(*PacletDocsInfo*)



Options[PacletDocsInfo]={
  "Language"->"English",
  "Root"->None,
  "LinkBase"->Automatic,
  "MainPage"->None(*,
	"Resources"\[Rule]None*)
  };
PacletDocsInfo[ops:OptionsPattern[]]:=
  SortBy[DeleteCases[DeleteDuplicatesBy[{ops},First],_->None],
    With[
      {
        o=
          Association@MapIndexed[#->#2[[1]]&, Keys@Options@PacletDocsInfo]
        },
      Lookup[o,First@#, Length@o+1]&]
      ];
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
        If[OptionValue["LinkBase"]===Automatic&&
          StringMatchQ[FileBaseName[dest], "Documentation_*"],
          "LinkBase"->StringSplit[FileBaseName[dest], "_"][[2]],
          Sequence@@{}
          ],
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
              If[MemberQ[p, "Guides/Overview.nb"],
                "Guides/Overview.nb",
                First@
                  SortBy[StringTrim[p, ".nb"],
                    EditDistance[FileBaseName@dest,FileBaseName@#]&]
                ]
            }]
        ]
      ]
    ];


(* ::Subsubsection::Closed:: *)
(*PacletExtensionData*)



(* ::Subsubsubsection::Closed:: *)
(*Docs*)



extractPacletExtensionDocsInfo[base_, dest_]:=
  Replace[base,
    {
      Automatic:>
        If[Length@
              FileNames["*.nb",
                FileNameJoin@{dest, "Documentation"},
                \[Infinity]]>0,
          "Documentation"->
            PacletDocsInfo[dest],
          Nothing
          ],
      r:_Rule|{___Rule}:>
        "Documentation"->Association@Flatten@{r},
      a_Association:>
        "Documentation"->a,
      _->Nothing
      }
    ]


(* ::Subsubsubsection::Closed:: *)
(*Kernel*)



extractPacletExtensionKernelInfo[base_, dest_]:=
  Replace[base,{
    Automatic:>
      If[AnyTrue[
          FileNameJoin@Flatten@{dest,#}&/@
            {
              FileBaseName[dest]<>".wl",
              FileBaseName[dest]<>".m",
              {"Kernel","init.m"}
              },
          FileExistsQ
          ],
        "Kernel"->
            <|
                "Root" -> ".", 
                "Context" -> FileBaseName@dest<>"`"
                |>,
        Nothing
        ],
    r:_Rule|{___Rule}:>
      "Kernel"->Association@Flatten@{r},
    a_Association:>
      "Kernel"->a,
    _->Nothing
    }]


(* ::Subsubsubsection::Closed:: *)
(*FrontEnd*)



extractPacletExtensionFrontEndInfo[base_, dest_]:=
  Replace[base,{
    Automatic:>
      With[
        {
          resources=
            Flatten@{
              Map[
                FileNames["*",
                  FileNameJoin@{dest,"FrontEnd",#},
                  \[Infinity]
                  ]&,{
                "TextResources",
                "SystemResources",
                "StyleSheets",
                "Palettes"
                }]
              }
          },
        If[Length@Select[Not@*DirectoryQ]@resources>0,
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
          ]
        ],
    r:_Rule|{___Rule}:>
      "FrontEnd"->Association@Flatten@{r},
    a_Association:>
      "FrontEnd"->a,
    _->Nothing
    }]


(* ::Subsubsubsection::Closed:: *)
(*Resources*)



extractPacletResourceLists[dest_, tag_]:=
  Replace[#, {a_, a_}:>a, 1]&@
  DeleteDuplicatesBy[First]@
    Map[
      {
        FileBaseName[#],
        FileNameDrop[#,
          FileNameDepth[dest]+1
          ]
        }&,
      Select[
        DeleteDuplicates@
          Join[
            FileNames["*",
              FileNameJoin@{dest, tag}
              ],
            FileNames["*.png"|"*.m"|"*.nb"|"*.wl"|"*.mx"|"*.wdx",
              FileNameJoin@{dest, "Resources"},
              3
              ],
            Select[DirectoryQ]@
              FileNames["*",
                FileNameJoin@{dest, tag},
                3
                ]
            ],
        Not@StringMatchQ[FileNameTake@#, ".DS_Store"|"Thumbs.db"]&
        ]
      ]


extractPacletExtensionResourceInfo[base_, dest_]:=
  Replace[base,
  {
    Automatic:>
      With[
        {
          dataResources=extractPacletResourceLists[dest, "Data"],
          basicResources=extractPacletResourceLists[dest, "Resources"]
          },
        If[Length@Join[dataResources, basicResources]>0,
          "Resource"->
            {
              If[Length@dataResources>0,
                <|
                  "Root" -> "Data",
                  "Resources" -> dataResources
                  |>,
                Nothing
                ],
              If[Length@basicResources>0,
                <|
                  "Root" -> "Resources",
                  "Resources" -> basicResources
                  |>,
                Nothing
                ]
              },
          Nothing
          ]
        ],
    r:_Rule|{___Rule}:>
      "Resource"->{Association@Flatten@{r}},
    a_Association:>
      "Resource"->{a},
    r:{__Association}:>
      "Resource"->r,
    _->Nothing
    }]


(* ::Subsubsubsection::Closed:: *)
(*AutoCompletionData*)



extractPacletExtensionAutoCompletionDataInfo[base_, dest_]:=
  Replace[base,{
        Automatic:>
          If[Length@
              FileNames["*.tr",
                  FileNameJoin@{dest,"AutoCompletionData"},
                  \[Infinity]]>0,
            "AutoCompletionData"->
              <|
                "Root" -> "AutoCompletionData"
                |>,
            Nothing
            ],
        r:_Rule|{___Rule}:>
          "AutoCompletionData"->Association@Flatten@{r},
        Except[_Association]->Nothing
        }]


(* ::Subsubsubsection::Closed:: *)
(*JLink*)



extractPacletExtensionJLinkInfo[base_, dest_]:=
  Replace[base, {
    Automatic:>
      If[Length@
          FileNames["*.jar",
            FileNameJoin@{dest, "Java"},
            \[Infinity]]>0,
        "JLink"->
          <|
            "Root" -> "Java"
            |>,
        Nothing
        ],
    r:_Rule|{___Rule}:>
      "JLink"->Association@Flatten@{r},
    Except[_Association]->Nothing
    }]


(* ::Subsubsubsection::Closed:: *)
(*LibraryLink*)



extractPacletExtensionLibraryLinkInfo[base_, dest_]:=
  Replace[base,
    {
      Automatic:>
        If[Length@
            Select[Not@*DirectoryQ]@
              FileNames[
                Except[".DS_Store"],
                FileNameJoin@{dest, "LibraryResources"},
                \[Infinity]]>0,
          "LibraryLink"->
            <|
              "Root" -> "LibraryResources"
              |>,
          Nothing
          ],
      r:_Rule|{___Rule}:>
        "LibraryLink"->Association@Flatten@{r},
      Except[_Association]->Nothing
      }
    ]


(* ::Subsubsubsection::Closed:: *)
(*Main*)



Options[PacletExtensionData]=
  {
    "Extensions"->Automatic,
    "Documentation"->Automatic,
    "Kernel"->Automatic,
    "FrontEnd"->Automatic,
    "Resource"->Automatic,
    "AutoCompletionData"->Automatic,
    "ChannelFramework"->Automatic,
    "JLink"->Automatic,
    "LibraryLink"->Automatic
    };
PacletExtensionData[pacletInfo_Association,dest_,ops:OptionsPattern[]]:=
  Merge[Merge[Last]]@{
    Replace[Lookup[pacletInfo, "Extensions"],
      Except[_Association?AssociationQ]:>
        <||>
      ],
    Replace[OptionValue["Extensions"],
      Except[_Association?AssociationQ]:>
        <||>
      ],
    extractPacletExtensionKernelInfo[
      OptionValue["Kernel"],
      dest
      ],
    extractPacletExtensionFrontEndInfo[
      OptionValue["FrontEnd"],
      dest
      ],
    extractPacletExtensionDocsInfo[
      OptionValue["Documentation"],
      dest
      ],
    extractPacletExtensionResourceInfo[
      OptionValue["Resource"],
      dest
      ],
    extractPacletExtensionAutoCompletionDataInfo[
      OptionValue["AutoCompletionData"],
      dest
      ],
    extractPacletExtensionJLinkInfo[
      OptionValue["JLink"],
      dest
      ],
    extractPacletExtensionLibraryLinkInfo[
      OptionValue["LibraryLink"],
      dest
      ]
    };


(* ::Subsubsection::Closed:: *)
(*PacletInfoExpression*)



validatePacletRules//ClearAll
validatePacletRules["BuildNumber"->s_String]:=
  If[!StringMatchQ[s, NumberString],
    Nothing,
    "BuildNumber"->s
    ];
validatePacletRules[_->""]:=
  Nothing;
validatePacletRules[e_]:=e;
validatePacletRules~SetAttributes~Listable    


$ValidPacletKeys=
  {
    "Name",
    "Version",
    "Creator",
    "URL",
    "Description",
    "Root",
    "WolframVersion",
    "MathematicaVersion",
    "Internal",
    "Loading",
    "Qualifier",
    "SystemID",
    "BuildNumber",
    "Tags",
    "Categories",
    "Authors",
    "Thumbnail",
    "Icon",
    "Extensions"
    };


Options[PacletInfoExpression]=
  Join[
    {
      "Name"->Automatic,
      "Version"->Automatic,
      "Creator"->Automatic,
      "URL"->Automatic,
      "Description"->Automatic,
      "Root"->Automatic,
      "WolframVersion"->Automatic,
      "MathematicaVersion"->Automatic,
      "Internal"->Automatic,
      "Loading"->Automatic,
      "Qualifier"->Automatic,
      "SystemID"->Automatic,
      "BuildNumber"->Automatic,
      "Tags"->Automatic,
      "Categories"->Automatic,
      "Authors"->Automatic,
      "Thumbnail"->Automatic,
      "Icon"->Automatic,
      "Extensions"->Automatic
      },
    Options@PacletExtensionData
    ];
PacletInfoExpression[ops:OptionsPattern[]]:=
  PacletManager`Paclet@@
    validatePacletRules@
    SortBy[DeleteCases[DeleteDuplicatesBy[{ops},First],_->None],
      With[
        {
          o=Association@MapIndexed[#->#2[[1]]&, Keys@Options@PacletInfoExpression]
          }, 
        Lookup[o, First@#, Length@o+1]&
        ]
      ];


(*PacletInfoExpression[dir]~~PackageAddUsage~~
	"generates a Paclet expression from dir";*)
Options[iPacletInfoExpression]=
  Options[PacletInfoExpression];
iPacletInfoExpression[
  dest_String?DirectoryQ,
  ops:OptionsPattern[]
  ]:=
  With[{pacletInfo=KeyDrop[PacletInfoAssociation[dest], "Location"]},
    PacletInfoExpression[
      Sequence@@FilterRules[{ops},
        Except["Kernel"|"Documentation"|"Extensions"|"FrontEnd"]],
      "Name"->FileBaseName@dest,
      "Extensions"->
        Replace[
          OptionValue["Extensions"],
          {
            Automatic:>
              KeyValueMap[
                Prepend[Normal@#2,#]&,
                PacletExtensionData[
                  pacletInfo,
                  dest,
                  FilterRules[{ops},
                    Options@PacletExtensionData
                    ]
                  ]
                ],
            Except[{{__String, __?OptionQ}..}]:>
              With[
                {
                  baseData=
                    PacletExtensionData[
                      pacletInfo,
                      dest,
                      FilterRules[{ops},
                        Options@PacletExtensionData
                        ]
                      ],
                  km=
                    Append[
                      Thread[
                        #->
                          Range[Length@#]
                        ]&@Keys@Options@PacletExtensionData,
                      _->1000
                      ]
                  },
                KeyValueMap[
                  Prepend[Normal@#2, #]&,
                  KeySortBy[baseData, ReplaceAll@km]
                  ]
              ]
            }
          ],
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
PacletInfoExpression[
  dest_String?DirectoryQ,
  ops:OptionsPattern[]
  ]:=
  iPacletInfoExpression[
    dest,
    FilterRules[{ops}, Options@PacletInfoExpression]
    ]


(* ::Subsubsection::Closed:: *)
(*PacletInfoExpressionBundle*)



cleanPacletForExport[pac_PacletManager`Paclet]:=
  DeleteDuplicatesBy[
    Map[
      If[StringQ[#[[1]]], ToExpression[#[[1]]], #[[1]]]->#[[2]]&, 
      Select[
        DeleteCases[pac, 
          (
            "Location"->_|"Resources"->_|
            _Symbol?(SymbolName[#]=="Location"&)->_|
            _Symbol?(SymbolName[#]=="Resources"&)->_)], 
        MatchQ[_String|_Symbol->_]
        ]
      ],
    Replace[
      {
        (s_Symbol->_):>SymbolName[s],
        (s_->_):>s
        }
      ]
    ]


prettyFormatPacletElement[elm_]:=
  StringReplace[
    StringDelete[
      FrontEndExecute[
        FrontEnd`ExportPacket[
          Cell[
            BoxData@
              GeneralUtilities`PrettyFormBoxes[elm, 1]/.
                TemplateBox[
                  {_, StyleBox[sym_, _], ___},
                  "DefinitionSymbol", 
                  ___
                  ]:>sym, 
            "Code",
            PageWidth->Infinity
            ], 
          "InputText"
          ]
        ][[1]],
      "\\"~~"\n"
      ],
    {
      StartOfLine->"  ",
      "\\n"->"\n"
      }
    ]


prettyFormatPacletString[
  pac_
  ]:=
  Block[{Internal`$ContextMarks=False},
    With[{bits=prettyFormatPacletElement/@List@@pac},
      "Paclet[\n"<>StringRiffle[bits, ",\n"]<>"\n ]"
      ]
    ]


Options[PacletInfoExpressionBundle]=
  Options[PacletInfoExpression];(*
PacletInfoExpressionBundle[paclet,dest]~~PackageAddUsage~~
	"bundles paclet into a PacletInfo.m file in dest";*)
PacletInfoExpressionBundle[
  paclet_PacletManager`Paclet,
  dest_String?DirectoryQ
  ]:=
  With[{pacletFile=FileNameJoin@{dest,"PacletInfo.m"}},
    Block[
      {
        $Context="PacletManager`Private`",
        $ContextPath={"System`", "PacletManager`", "PacletManager`Private`"}
        },
      Export[pacletFile, 
        prettyFormatPacletString[cleanPacletForExport[paclet]],
        "Text"
        ]
      ];
    pacletFile
    ];
PacletInfoExpressionBundle[
  dest_String?DirectoryQ,
  ops:OptionsPattern[]
  ]:=
  PacletInfoExpressionBundle[
    PacletInfoExpression[dest,ops],
    dest
    ];


Options[PacletInfoGenerate]=
  Options[PacletInfoExpressionBundle];
PacletInfoGenerate[
  dest_String?DirectoryQ,
  ops:OptionsPattern[]
  ]:=
  PacletInfoExpressionBundle[dest,ops]


(* ::Subsubsection::Closed:: *)
(*PacletLookup*)



PacletLookup//Clear


PacletLookup[p:{$pacletInfoSpec..}|$pacletInfoSpec, props_]:=
  Lookup[PacletInfoAssociation@p,props];
PacletLookup[p:{$pacletInfoSpec..}|$pacletInfoSpec, props_, def_]:=
  Lookup[PacletInfoAssociation@p, props, def];
PacletLookup~SetAttributes~HoldRest


(* ::Subsubsection::Closed:: *)
(*PacletOpen*)



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
      ]/;AllTrue[Flatten@{locs},StringQ]
    ];


(* ::Subsubsection::Closed:: *)
(*PacletAutoPaclet*)



PacletAutoPaclet::nopac=
  "Couldn't find any paclet to autogenerate for ``";


Options[PacletAutoPaclet]=
  Join[
    Options[PacletInfoExpressionBundle],
    {
      "Bundle"->False
      }
    ];
PacletAutoPaclet[
  dir:_String?DirectoryQ|Automatic:Automatic, 
  f_String?FileExistsQ,
  ops:OptionsPattern[]
  ]:=
  With[{bn=StringSplit[FileBaseName[f], Except[WordCharacter|"_"]][[1]]},
    With[
    {
      d=
        CreateDirectory[
          FileNameJoin@{Replace[dir, Automatic:>CreateDirectory[]], bn},
          CreateIntermediateDirectories->True
          ]
      },
      Which[
        (* f is a directory, so copy it into the new place *)
        DirectoryQ@f,
          Quiet[DeleteDirectory[d]];
          If[DirectoryQ@d,
            $Failed,
            CopyDirectory[f, d];
            If[!FileExistsQ@FileNameJoin@{d, "PacletInfo.m"},
              PacletInfoExpressionBundle[d, ops]
              ]
            ],
        MatchQ[FileExtension[f],
          Alternatives@@(CreateArchive;CreateArchiveDump`$CONVERTERS)
          ],
          ExtractArchive[f, d];
          Which[
            FileExistsQ@FileNameJoin@{d, "PacletInfo.m"},
              d,
            DirectoryQ@FileNameJoin@{d, bn},
              CopyDirectory[FileNameJoin@{d, bn}, 
                FileNameJoin@{DirectoryName[d], bn<>"__"}
                ];
              DeleteDirectory[d, DeleteContents->True];
              RenameDirectory[FileNameJoin@{DirectoryName[d], bn<>"__"}, d],
            True,
              PacletInfoExpressionBundle[d, ops]
            ],
        True,
          Switch[FileExtension[f],
            "m"|"wl",
              CopyFile[f, FileNameJoin@{d, FileNameTake@f}],
            "nb",
              CopyFile[f, FileNameJoin@{d, FileNameTake@f}];
              Export[
                FileNameJoin@{d, FileBaseName[f]<>".m"},
                "(*Open package notebook*)
CreateDocument[
	Import@
		StringReplace[$InputFileName,\".m\"->\".nb\"]
	]",
              "Text"
              ];
            ];
          PacletInfoExpressionBundle[d, ops]
        ];
      If[TrueQ@OptionValue["Bundle"], 
        (If[dir===Automatic, DeleteDirectory[d, DeleteContents->True]];#)&@
          PacletBundle@d, 
        d]
      ]
    ];
PacletAutoPaclet[
  dir:_String?DirectoryQ|Automatic:Automatic,
  pac:_PacletManager`Paclet?(StringQ@#["Location"]&), 
  ops:OptionsPattern[]
  ]:=
  PacletAutoPaclet[dir, pac["Location"], ops];
PacletAutoPaclet[
  dir:_String?DirectoryQ|Automatic:Automatic,
  s_String?(AllTrue[URLParse[#, {"Scheme", "Domain"}], #=!=None&]&), 
  ops:OptionsPattern[]
  ]:=
  PacletAutoPaclet[
    dir, 
    First@URLDownload[s],
    ops
    ];
PacletAutoPaclet[
  dir:_String?DirectoryQ|Automatic:Automatic,
  s_String?(Not@*FileExistsQ), 
  ops:OptionsPattern[]
  ]:=
  With[{pf=PacletManager`PacletFind[s]},
    If[Length@pf>0,
      PacletAutoPaclet[dir, pf[[1]], ops],
      Message[PacletAutoPaclet::nopac, s];
      $Failed
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*PacletBundle*)



Options[PacletBundle]=
  Join[
    {
      "RemovePaths"->{},
      "RemovePatterns"->{},
      "ConfigFile"->Automatic,
      "BuildRoot":>$PacletBuildRoot
      },
    Options[PacletInfoExpressionBundle]
    ];
PacletBundle[dir:(_String|_File)?DirectoryQ, ops:OptionsPattern[]]:=
  With[{
    rmpaths=
      Replace[
        Flatten@List@OptionValue["RemovePaths"],
        Except[{__?StringPattern`StringPatternQ}]:>{}
        ],
    rmpatterns=
      Replace[
        Flatten@List@OptionValue["RemovePatterns"],
        Except[{__?StringPattern`StringPatternQ}]:>{}
        ],
    pacletDir=
      FileNameJoin@{
        OptionValue["BuildRoot"],
        $PacletBuildExtension,
        FileBaseName@dir
        },
    extraData=
      Replace[Except[_?OptionQ]:>{}]@
        Replace[OptionValue["ConfigFile"],
          {
            Automatic:>
              With[{test=FileNameJoin@{dir, "Config", "BundleInfo.m"}},
                If[FileExistsQ[test],
                  Import[test],
                  None
                  ]
                ],
            f_String?FileExistsQ:>
              Import[f],
            Except[_String?FileExistsQ]:>
              None
            }
          ]
    },
    If[!FileExistsQ@DirectoryName[pacletDir],
      CreateDirectory[DirectoryName[pacletDir], CreateIntermediateDirectories->True]
      ];
    With[
      {
        fullPathSpec=
          Join[
            Flatten[{rmpaths}, 1], 
            Flatten[{Lookup[extraData, "RemovePaths", {}]}, 1]
            ],
        fullPatternSpec=
          Join[
            Flatten[{rmpatterns}, 1], 
            Flatten[{Lookup[extraData, "RemovePatterns", {}]}, 1]
            ]
        },
      If[Length@Join[fullPathSpec, fullPatternSpec]===0,
        (* just do a simple PackPaclet and move the paclet *)
        With[{p=PacletManager`PackPaclet[dir]},
          RenameFile[
            p,
            FileNameJoin@{
              DirectoryName[pacletDir],
              FileNameTake[p]
              },
            OverwriteTarget->True
            ];
          FileNameJoin@{
            DirectoryName[pacletDir],
            FileNameTake[p]
            }
          ],
        (* copy the dir, remove the dangerous junk, etc. *)
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
              fullPathSpec,
              FileNameDrop[#,FileNameDepth@pacletDir]&/@
                FileNames[fullPatternSpec, pacletDir, \[Infinity]]
              ]
            }
          ];
        With[{pacletFile=PacletManager`PackPaclet[pacletDir]},
          pacletFile
          ]
        ]
      ]
    ];


(*
	Prep the dir first when passed just a file
	*)


PacletBundle[f:(_String|_File)?FileExistsQ, ops:OptionsPattern[]]:=
  With[{d=CreateDirectory[]},
    (DeleteDirectory[d, DeleteContents->True];#)&@
      PacletBundle[
        PacletAutoPaclet[d, f,
          FilterRules[
            {
              ops,
              "Description"->
                TemplateApply[
                  "Autogenerated paclet from ``",
                  FileNameTake[f]
                  ]
              },
            Options[PacletInfoExpressionBundle]
            ]
          ], 
        ops
        ]
    ]


PacletBundle[
  p_PacletManager`Paclet?(StringQ@#["Location"]&), 
  ops:OptionsPattern[]
  ]:=
  PacletBundle[p["Location"], ops];
PacletBundle[
  s:(_String|{_String, _String})?(Length[PacletManager`PacletFind[#]]>0&), 
  ops:OptionsPattern[]
  ]:=
  PacletBundle[PacletManager`PacletFind[s][[1]], ops];


(* ::Subsubsection::Closed:: *)
(*PacletInstalledQ*)



Options[PacletInstalledQ]=
  Options[PacletManager`PacletFind];
PacletInstalledQ[pac:_String|{_String, _String}, ops:OptionsPattern[]]:=
  Length@PacletManager`PacletFind[pac, ops]>0;
PacletInstalledQ[pac_PacletManager`Paclet, ops:OptionsPattern[]]:=
  PacletInstalledQ[{pac["Name"], pac["Version"]}];


(* ::Subsubsection::Closed:: *)
(*PacletExistsQ*)



Options[PacletExistsQ]=
  Options[PacletInstalledQ];
PacletExistsQ[pac:_String|{_String, _String}, ops:OptionsPattern[]]:=
  PacletInstalledQ[pac, ops]||
    Length@PacletManager`PacletFindRemote[pac, ops]>0;


(* ::Subsection:: *)
(*Sites*)



(* ::Subsubsection::Closed:: *)
(*pacletStandardServerName*)



pacletStandardServerName[serverName_]:=
  Replace[
    Replace[
      serverName,
      {
        Automatic:>
          "PacletServer",
        Default:>
          Lookup[$PacletServer, "ServerName"]
        }
      ],{
    e:Except[_String]:>(Nothing)
    }]


(* ::Subsubsection::Closed:: *)
(*pacletStandardServerBase*)



pacletStandardServerBase[serverBase_,
  cc_:Automatic,
  kc_:Automatic
  ]:=
  If[StringQ[#]&&DirectoryQ@#, ExpandFileName[#], #]&@
    Replace[
      Replace[
        serverBase,
        {
          Default:>
            Lookup[$PacletServer, "ServerBase"]
          }
        ],{
      e:Except[
        _String|_CloudObject|_CloudDirectory|CloudObject|CloudDirectory|
        _File|_URL
        ]:>
          Replace[CloudDirectory[],
            Except[_CloudObject]:>
              (
              pacletCloudConnect[serverBase, cc, kc];
              CloudDirectory[]
              )
            ],
      f:(_String|_File)?DirectoryQ:>
        ExpandFileName[f]
      }]


(* ::Subsubsection::Closed:: *)
(*pacletStandardServerExtension*)



pacletStandardServerExtension[serverExtension_]:=
  Replace[
    Replace[
      serverExtension,
      {
        Automatic:>
          Nothing,
        Default:>
          Lookup[$PacletServer, "ServerExtension"]
        }
      ],{
    e:Except[_String|{___String}]:>{},
    s_String:>DeleteCases[""]@URLParse[s,"Path"]
    }]


(* ::Subsubsection::Closed:: *)
(*pacletStandardServerPermissions*)



pacletStandardServerPermissions[perms_]:=
  Replace[
    Replace[
      perms,
      Automatic|Default:>
        Lookup[$PacletServer,Permissions]
      ],{
    e:Except[_String]:>$Permissions
    }]


(* ::Subsubsection::Closed:: *)
(*PacletSiteURL*)



PacletSiteURL::nobby="Unkown site base ``";


$PacletUploadDomains=
  <|
    "www.github.com"->
      Function[PacletAPIUpload["GitHub", ##]],
    "drive.google.com"->
      Function[PacletAPIUpload["GoogleDrive", ##]],
    "www.dropbox.com"->
      Function[PacletAPIUpload["Dropbox", ##]]
    |>


pacletCloudConnect[base_, cc_, useKeychain_]:=
  (
    With[
      {
        kc=
          Replace[useKeychain,
            Automatic:>
              $PacletUseKeychain
            ],
        ccReal=
          Replace[
            cc,
            Automatic:>
              Replace[base,
                Verbatim[CloudObject][o_,___]:>
                  DeleteCases[URLParse[o, "Path"], ""][[2]]
                ]
            ]
        },
      Replace[
        ccReal,
        {
          a:$KeychainCloudAccounts?(kc&):>
            KeychainConnect[a],
          k_Key:>
            KeychainConnect[k],
          s_String:>
            If[$WolframID=!=s||
              (StringQ[$WolframID]&&StringSplit[$WolframID, "@"][[1]]=!=s),
              If[kc, 
                KeychainConnect,
                CloudConnect
                ][If[!StringContainsQ[s, "@"], s<>"@gmail.com", s]]
              ],
          {s_String,p_String}:>
            If[$WolframID=!=s, 
              If[kc, 
                KeychainConnect,
                CloudConnect
                ][s,p]
              ],
          {s_String,e___,CloudBase->b_,r___}:>
            If[$CloudBase=!=b||$WolframID=!=s,
              If[kc, 
                KeychainConnect,
                CloudConnect
                ][s,e,CloudBase->b,r]
              ],
          _:>
            If[!StringQ[$WolframID], CloudConnect[]]
          }
        ]
      ];
    If[!StringQ[$WolframID],
      PackageRaiseException[
        Automatic,
        PacletSiteURL::nowid
        ]
      ]
    );


Options[PacletSiteURL]=
  {
    "ServerBase"->
      Automatic,
    "ServerName"->
      Automatic,
    "ServerExtension"->
      Automatic,
    "Username"->
      Automatic,
    CloudConnect->
      Automatic,
    "UseKeychain"->
      Automatic
    };
PacletSiteURL::nowid="$WolframID isn't a string. Try cloud connecting";
PacletSiteURL[ops:OptionsPattern[]]:=
  PackageExceptionBlock["PacletTools"]@
    With[
      {
        ext=
          pacletStandardServerExtension@OptionValue["ServerExtension"],
        base=
          pacletStandardServerBase[
            OptionValue["ServerBase"],
            OptionValue@CloudConnect, 
            OptionValue@"UseKeychain"
            ],
        name=
          pacletStandardServerName@OptionValue["ServerName"]
        },
      Switch[base,
        $CloudBase|"Cloud"|CloudObject|CloudDirectory|
          _CloudObject|_CloudDirectory,
          pacletCloudConnect[
            base, 
            OptionValue@CloudConnect, 
            OptionValue@"UseKeychain"
            ];
          URLBuild@
            <|
              "Scheme"->"http",
              "Domain"->
                Replace[base,
                  {
                    "Cloud"|CloudObject|CloudDirectory->
                      URLParse[$CloudBase,"Domain"],
                    d_String|CloudObject[d_,___]:>
                      URLParse[d,"Domain"]
                    }
                  ],
              "Path"->
                Flatten@{
                  "objects",
                  Replace[OptionValue["Username"],
                    {
                      Automatic:>
                        URLParse[$CloudRootDirectory[[1]], "Path"][[-1]]
                      }
                    ],
                  ext,
                  name
                  }
              |>,
        _String?(KeyMemberQ[$PacletUploadDomains, URLParse[#, "Domain"]]&),
          PackageRaiseException@
            "Non-cloud paclet support not yet complete",
        _String?(AllTrue[URLParse[#, {"Scheme", "Domain"}], #=!=None&]&),
          URLBuild@
            Flatten@{
              base,
              ext,
              name
              },
        _String?(StringMatchQ[FileNameJoin@{$RootDirectory,"*"}]),
          "file://"<>
            URLBuild@Key["Path"]@URLParse@
              URLBuild@Flatten@
                {
                  base,
                  ext,
                  name
                  }//StringReplace[URLDecode[#]," "->"%20"]&,
        _?SyncPathQ,
          "file://"<>
            URLBuild@Key["Path"]@URLParse@
              URLBuild@Join[{
                SyncPath[
                  Replace[
                    StringSplit[base,":",2],{
                    {r_,p_}:>
                      StringJoin@{r,":",
                        URLBuild@Flatten@{
                          ext,
                          p}
                        },
                    {r_}:>
                      StringJoin@{r,":",
                        URLBuild@Flatten@{
                          ext
                          }
                        }
                    }]
                  ],
                name
                }]//StringReplace[URLDecode[#]," "->"%20"]&,
        _,
          PackageRaiseException[
            Automatic,
            PacletSiteURL::nobby,
            base
            ]
        ]
      ];


(* ::Subsubsection::Closed:: *)
(*PacletSiteFiles*)



Options[PacletSiteFiles]=
  Join[
    {
      "MergePacletInfo"->Automatic
      },
    Options@PacletSiteURL
    ];
PacletSiteFiles[infoFiles_, ops:OptionsPattern[]]:=
  DeleteCases[Except[$PacletFilePatterns]]@
    Replace[
      Replace[
        Flatten@{ infoFiles, OptionValue["MergePacletInfo"] },{
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
      s_String?FileExistsQ:>s,
      s_String?(
        MatchQ[Lookup[URLParse[#],{"Scheme","Domain","Path"}],
          {_String,None,{__,_?(StringMatchQ[Except["."]..])}}
          ]&
        ):>
        StringReplace[URLBuild@{s,"PacletSite.mz"},
          StartOfString~~"file:"->
            "file://"
          ],
      None:>
        Sequence@@{},
      All:>
        StringReplace[
          URLBuild@{
            PacletSiteURL[
              FilterRules[{ops},Options@PacletSiteURL]
              ],
            "PacletSite.mz"
            },{
          StartOfString~~"file:"->"file://",
          "%20"->" "
          }],
      s_String?(
        MatchQ[Lookup[URLParse[#],{"Scheme","Domain","Path"}],
          {None,None,{_?(StringMatchQ[Except["."]..])}}
          ]&):>
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


(* ::Subsubsection::Closed:: *)
(*PacletSiteInfo*)



pacletSiteMExtract[mzFile_,dirExt_:Automatic]:=
  If[FileExistsQ@mzFile,
    With[{dir=CreateDirectory[]},
      Replace[
        Quiet[ExtractArchive[mzFile,dir,"PacletSite.m"],ExtractArchive::infer],
        Except[{__}]:>
          Quiet[
            ExtractArchive[mzFile,dir,"*/PacletInfo.m"],
            ExtractArchive::infer
            ]
        ]
      ],
    $Failed
    ];


PacletSiteInfo//Clear


Options[PacletSiteInfo]=
  Options[PacletSiteFiles];
(*PacletSiteInfo[specs]~~PackageAddUsage~~
	"extracts the PacletSite info stored in specs";*)
PacletSiteInfo[infoFiles:Except[_?OptionQ]|All|{}:All,ops:OptionsPattern[]]:=
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
        ]&/@PacletSiteFiles[Flatten@{infoFiles},ops]//Flatten
    },
    Block[
      {
        $Context="PacletManager`Private`", 
        $ContextPath={"System`", "PacletManager`", "PacletManager`Private`"}
        },
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
                  {
                    (s_Symbol->v_):>
                      (SymbolName[s](*s*)->v),
                    (s_String->v_):>
                      (*ToExpression[s]*)s->v,
                    _:>
                      Sequence@@{}
                    },
                  1]&/@Flatten@{imp}
                ]&,
              pacletInfos
              ]//DeleteDuplicatesBy[
                Lookup[Association@@#,{"Name","Version"}]&
                ]
        },
        DeleteCases[pacletsite,Except[_PacletManager`Paclet]]
        ]
      ]
    ];


(* ::Subsubsection::Closed:: *)
(*PacletSiteInfoDataset*)



(*PacletSiteInfoDataset::usages="";
PacletSiteInfoDataset[site]~PackageAddUsage~
	"formats a Dataset from the PacletInfo in site";
PacletSiteInfoDataset[files]~PackageAddUsage~
	"formats from the PacletSiteInfo in files";*)


PacletSiteInfoDataset//Clear


Options[PacletSiteInfoDataset]=
  Options[PacletSiteInfo];
PacletSiteInfoDataset[PacletManager`PacletSite[p___]]:=
  Dataset@Map[PacletInfoAssociation, {p}];
PacletSiteInfoDataset[files:Except[_?OptionQ]|All|{}:All,ops:OptionsPattern[]]:=
  PacletSiteInfoDataset[PacletSiteInfo[files,ops]];


(* ::Subsubsection::Closed:: *)
(*PacletSiteBundle*)



pacletSiteFileName[br_, fp_, if_, baseName_]:=
  FileNameJoin@{
    With[{d=
      FileNameJoin@{
        br,
        $PacletBuildExtension
        }
      },
      If[!FileExistsQ@d,
        CreateDirectory@d
        ];
      d
      ],
    Replace[fp,{
      Automatic:>
        With[{f=First@if},
          If[StringMatchQ[FileNameTake[f],"*.*"],
            DirectoryName[f],
            FileBaseName[f]
            ]
          ]<>"-",
      s_String:>(s<>"-"),
      _->""
      }]<>baseName
    }


Options[PacletSiteBundle]=
  Join[
    {
      "BuildRoot":>$TemporaryDirectory,
      "FilePrefix"->None
      },
    Options@PacletSiteInfo
    ];
(*PacletSiteBundle[infoFiles]~~PackageAddUsage~~
	"bundles the PacletInfo.m files found in infoFiles into a compressed PacletSite file";*)
PacletSiteBundle[dir_String?DirectoryQ, ops:OptionsPattern[]]:=
  PacletSiteBundle[
    FileNames["*.paclet",dir,2],
    ops
    ];
PacletSiteBundle[
  infoFiles:$PacletFilePatterns|{$PacletFilePatterns...},
  ops:OptionsPattern[]
  ]:=
  Block[
    {
      $ContextPath={"System`", "PacletManager`Private`", "PacletManager`"}, 
      $Context="PacletManager`Private`",
      Internal`$ContextMarks=False
      },
    Export[
      pacletSiteFileName[
        OptionValue["BuildRoot"], 
        OptionValue["FilePrefix"],
        {infoFiles},
        "PacletSite.mz"
        ],
      Map[
        cleanPacletForExport,
        PacletSiteInfo[
          infoFiles,
          FilterRules[{ops},
            Options@PacletSiteInfo
            ]
          ]
        ],
      {"ZIP", "PacletSite.m"}
      ]
    ];


(* ::Subsection:: *)
(*Installers*)



(* ::Subsubsection::Closed:: *)
(*PacletInstallerURL*)



Options[PacletInstallerURL]=
  Options@PacletSiteURL;
PacletInstallerURL[ops:OptionsPattern[]]:=
  StringReplace[
    URLBuild@{PacletSiteURL[ops],"Installer.m"},
    StartOfString~~"file:"->"file://"
    ];


(* ::Subsubsection::Closed:: *)
(*PacletInstallerScript*)



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
                  PacletInstallerScript::savefail=
                    "No paclet found at ``";
                  Message[PacletInstallerScript::savefail,file];
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
                      PacletInstallerScript::savefail=
                        "No paclet found at ``";
                      Message[PacletInstallerScript::savefail,file];
                      $Failed
                      ]&/@paclets
                    ]
                  ]
                ]
            }],
        True,
          PacletInstallerScript::unclear="Unclear how to install paclet from site ``";
          Message[PacletInstallerScript::unclear,ps];
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


(* ::Subsubsection::Closed:: *)
(*PacletUploadInstaller*)



Options[PacletUploadInstaller]:=
  DeleteDuplicatesBy[First]@
    Join[
      Options@PacletInstallerScript,
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


(* ::Subsubsection::Closed:: *)
(*PacletUninstallerURL*)



Options[PacletUninstallerURL]=
  Options@PacletSiteURL;
PacletUninstallerURL[ops:OptionsPattern[]]:=
  StringReplace[
    URLBuild@{PacletSiteURL[ops],"Uninstaller.m"},
    StartOfString~~"file:"->"file://"
    ];


(* ::Subsubsection::Closed:: *)
(*PacletUninstallerScript*)



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
          PacletUninstallerScript::unclear="Unclear how to uninstall paclet from site ``";
          Message[PacletUninstallerScript::unclear,ps];
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


(* ::Subsubsection::Closed:: *)
(*PacletUploadUninstaller*)



Options[PacletUploadUninstaller]:=
  DeleteDuplicatesBy[First]@
    Join[
      Options@PacletUninstallerScript,
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


(* ::Subsubsection::Closed:: *)
(*PacletInstallerLink*)



Options[PacletInstallerLink]=
  Options@CloudExport;
PacletInstallerLink[pacletURL:_String,uri_,ops:OptionsPattern[]]:=
  "wolfram+cloudobject:"<>
    First@
      CloudExport[
        Notebook[{
          Cell[
            BoxData@ToBoxes@Unevaluated[PacletManager`PacletInstall@pacletURL],
            "Input"
            ]
          }],
        "NB",
        uri,
        Permissions->
          pacletStandardServerPermissions@OptionValue[Permissions],
        ops
        ];
PacletInstallerLink[pacletURL:{__String},uri_,ops:OptionsPattern[]]:=
  "wolfram+cloudobject:"<>
    First@
      CloudExport[
        Notebook[{
          Cell[
            BoxData@ToBoxes@Unevaluated[PacletManager`PacletInstall/@pacletURL],
            "Input"
            ]
          }],
        "NB",
        uri,
        Permissions->
          pacletStandardServerPermissions@OptionValue[Permissions],
        ops
        ];
PacletInstallerLink[c_CloudObject,uri_,ops:OptionsPattern[]]:=
  PacletInstallerLink[First@c,uri,ops];
PacletInstallerLink[c:{__CloudObject},uri_,ops:OptionsPattern[]]:=
  PacletInstallerLink[First/@c,uri,ops];


(* ::Subsubsection::Closed:: *)
(*PacletSiteInstall*)



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


(* ::Subsubsection::Closed:: *)
(*PacletSiteUninstall*)



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
(*Upload*)



(* ::Subsubsection::Closed:: *)
(*PacletSiteUpload*)



(* ::Subsubsubsection::Closed:: *)
(*pacletSiteUpload*)



pacletSiteUpload//Clear


Options[pacletSiteUpload]=
  Join[
    Options[PacletSiteURL],{
      Permissions->Automatic
    }];
pacletSiteUpload[
  CloudObject[site_],
  pacletMZ:(_String|_File)?FileExistsQ,
  ops:OptionsPattern[]
  ]:=
  With[{res=
    CopyFile[
      pacletMZ,
      CloudObject[
        URLBuild@{site,"PacletSite.mz"},
        Permissions->
          pacletStandardServerPermissions@OptionValue[Permissions]
        ]
      ]
    },
    Take[res, 1]/;MatchQ[res,_CloudObject]
    ]
pacletSiteUpload[
  dir:(_String|_File)?DirectoryQ,
  pacletMZ:(_String|_File)?FileExistsQ,
  ops:OptionsPattern[]
  ]:=
  CopyFile[pacletMZ,
    FileNameJoin@{dir,"PacletSite.mz"},
    OverwriteTarget->True
    ];
pacletSiteUpload[
  site:(_String|_URL),
  pacletMZ:(_String|_File)?FileExistsQ,
  ops:OptionsPattern[]
  ]:=
  If[URLParse[site,"Scheme"]==="file",
    pacletSiteUpload[
      URLParse[site,"Path"]//FileNameJoin,
      pacletMZ,
      ops],
    pacletSiteUpload[
      CloudObject@First@Flatten[URL@site,1,URL],
      pacletMZ,
      ops
      ]
    ];


(* ::Subsubsubsection::Closed:: *)
(*PacletSiteUpload*)



Options[PacletSiteUpload]=
  DeleteDuplicatesBy[First]@
    Join[
      Options[pacletSiteUpload],
      Options[PacletSiteBundle]
      ];
PacletSiteUpload[
  site_,
  pacletMZ:(_String|_File)?(FileExistsQ@#&&FileExtension@#=="mz"&),
  ops:OptionsPattern[]
  ]:=
  With[{res=
    pacletSiteUpload[
      Replace[site,
        Automatic:>
          PacletSiteURL@
            FilterRules[{ops},
              Options@PacletSiteURL
              ]
        ],
      pacletMZ,
      FilterRules[{ops},Options@pacletSiteUpload]
      ]
    },
    res/;!MatchQ[res,_pacletSiteUpload]
    ];
PacletSiteUpload[
  pacletMZ:(_String|_File)?(FileExistsQ@#&&FileExtension@#=="mz"&),
  ops:OptionsPattern[]
  ]:=
  With[{
    site=PacletSiteURL@FilterRules[{ops},Options@PacletSiteURL]
    },
    With[{res=
      pacletSiteUpload[site,pacletMZ,
        FilterRules[{ops},Options@pacletSiteUpload]
        ]},
      res/;!MatchQ[res,_pacletSiteUpload]
      ]
    ];
PacletSiteUpload[
  site:Except[{}, _String|_?OptionQ],
  infoFiles:$PacletFilePatterns|{$PacletFilePatterns...},
  ops:OptionsPattern[]
  ]:=
  With[{mz=
    PacletSiteBundle[
      infoFiles,
      FilterRules[{ops},Options@PacletSiteBundle]
      ]
    },
    With[{res=
      PacletSiteUpload[
        Replace[site,Automatic:>(Sequence@@{})],
        mz,
        ops
        ]
      },
      res/;!MatchQ[res,_PacletSiteUpload]
      ]
    ];
PacletSiteUpload[
  site:Except[{}, _String|_?OptionQ],
  PacletManager`PacletSite[infoFiles:$PacletFilePatterns...],
  ops:OptionsPattern[]
  ]:=
  PacletSiteUpload[site,{infoFiles},ops];


(* ::Subsubsection::Closed:: *)
(*PacletAPIUpload*)



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


(* ::Subsubsection::Closed:: *)
(*PacletUpload*)



(* ::Subsubsubsection::Closed:: *)
(*URL Based Paclets*)



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


(* ::Subsubsubsection::Closed:: *)
(*Built PacletFindBuiltFile*)



PacletFindBuiltFile//Clear


Options[PacletFindBuiltFile]=
  {
    "UseCachedPaclets"->True,
    "BuildPaclets"->True
    };
PacletFindBuiltFile[
  f:_PacletManager`Paclet|_String|_URL|_File,
  ops:OptionsPattern[]
  ]:=
  With[
    {
      useCached=TrueQ@OptionValue["UseCachedPaclets"],
      build=TrueQ@OptionValue@"BuildPaclets"
      },
    Which[
      MatchQ[f,_PacletManager`Paclet],
        (* We're handed a Paclet expression so we confirm that a .paclet file exists for it or build it ourselves *)
        With[{
          info=
            Lookup[
              PacletManager`PacletInformation@f,
              {"Location","Name","Version"}
              ]},
          If[useCached&&FileExistsQ@(info[[1]]<>".paclet"),
            info[[1]]<>".paclet",
            Replace[PacletFindBuiltFile[info[[2;;3]],ops],
              None:>
                If[DirectoryQ@info[[1]],
                  If[build,
                    PacletBundle[info[[1]]],
                    True
                    ],
                  None
                  ]
              ]
            ]
          ],
      MatchQ[f, (_File|_String)?DirectoryQ]&&
        !FileExistsQ[FileNameJoin@{f,"PacletInfo.m"}],
        (* prep non-paclet directories for packing *)
        If[build,
          PacletInfoExpressionBundle[Replace[f,File[s_]:>s]];
          PacletFindBuiltFile[f,ops],
          True
          ],
      MatchQ[f,(_String|_URL)?urlBasedPacletQ],
        (* We're handed a URL so we just return that *)
        First@Flatten[URL[f],1,URL],
      MatchQ[f, _String?(Length@PacletManager`PacletFind[#]>0&)],
        (* found a paclet to pack by name *)
        PacletFindBuiltFile[
          First@PacletManager`PacletFind[f],
          ops
          ],
      MatchQ[f, _File|_String|True|False],
        Replace[{
          File[fil_]:>fil
          }]@
          SelectFirst[
            {
              If[TrueQ@DirectoryQ@f,
                (* handed a directory *)
                If[TrueQ@FileExistsQ@FileNameJoin@{f,"PacletInfo.m"},
                  (* if f is a paclet directory *)
                  With[{a=PacletInfoAssociation[FileNameJoin@{f,"PacletInfo.m"}]},
                    (* check again for the paclet file by version*)
                    Replace[PacletFindBuiltFile[Lookup[a,{"Name","Version"}],ops],
                      {
                        None:>
                          If[build,
                            (* needs to be built *)
                            PacletBundle[f],
                            True
                            ],
                        Except[_String|_File]:>
                          Nothing
                        }
                      ]
                    ],
                  Nothing
                  ],
                (* Only thing left it could be is a file *)
                With[{fname=StringTrim[f, "."<>FileExtension[f]]<>".paclet"},
                  (* If its paclet file exists *)
                  If[FileExistsQ@fname,
                    fname,
                    If[build,
                      If[FileExistsQ@f,
                        PacletBundle[f],
                        None
                        ],
                      True
                      ]
                    ]
                  ]
                ],
              If[TrueQ@useCached,
                (* Check for default cached paclet *)
                FileNameJoin@{
                  $PacletBuildRoot,
                  $PacletBuildExtension,
                  StringTrim[f,"."<>FileExtension[f]]<>".paclet"
                  },
                Nothing
                ]
            },
            TrueQ[#]||
              (MatchQ[#, _File|_String]&&FileExistsQ[#])&,
            None
            ],
    True,
      None
      ]
    ];
PacletFindBuiltFile[{f_String,v_String},ops:OptionsPattern[]]:=
  PacletFindBuiltFile[f<>"-"<>v<>".paclet",ops];
PacletFindBuiltFile[Rule[s_,p_],ops:OptionsPattern[]]:=
  Rule[s,PacletFindBuiltFile[p,ops]];
PacletFindBuiltFile[None,___]:=None;
builtPacletFileQ[spec_,
  ops:OptionsPattern[]
  ]:=
  !MatchQ[PacletFindBuiltFile[spec,"BuildPaclets"->False,ops],None|(_->None)];


(* ::Subsubsubsection::Closed:: *)
(*pacletUploadPostProcess*)



pacletUploadPostProcess[assoc_, uploadInstallLink_, site_, perms_]:=
  Replace[uploadInstallLink,
  {
    True:>
      Append[#,
        "PacletInstallLinks"->
          PacletInstallerLink[
            #["PacletFiles"],
            URLBuild@{site,"InstallerNotebook.nb"},
            Permissions->
              pacletStandardServerPermissions@perms
            ]
        ],
    s_String:>
      Append[#,
        "PacletInstallLinks"->
          PacletInstallerLink[
            #["PacletFiles"],
            URLBuild@{site,s},
            Permissions->
              pacletStandardServerPermissions@perms
            ]
        ],
    Automatic:>
      Append[#,
        "PacletInstallLinks"->
          Map[
            Function[
              PacletInstallerLink[
                #,
                URLBuild@{
                  site,
                  StringReplace[
                    URLParse[#,"Path"][[-1]],
                    ".paclet"~~EndOfString->".nb"
                    ]},
                Permissions->
                  pacletStandardServerPermissions@perms
                ]
              ],
            #["PacletFiles"]
            ]
        ],
    _:>#
    }
    ]&@assoc;
pacletUploadPostProcess[uploadInstallLink_, site_, perms_][assoc_]:=
  pacletUploadPostProcess[assoc, uploadInstallLink, site, perms]


(* ::Subsubsubsection::Closed:: *)
(*pacletUploadBuildPacletFile*)



pacletUploadBuildPacletCloudObject[url_, perms_, v_]:=
  CloudObject[
    URLBuild@{
      url,
      "Paclets",
      Replace[v,
        {
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
          f:_String|_File:>
            If[FileExistsQ@f,
              FileNameTake@f,
              URLParse[f,"Path"][[-1]]
              ],
          _:>$Failed
          }
        ]                              
      },
    Permissions->
      pacletStandardServerPermissions@perms
    ];
pacletUploadBuildPacletCloudObject[url_, perms_][v_]:=
  pacletUploadBuildPacletCloudObject[url, perms, v]


(* ::Subsubsubsection::Closed:: *)
(*pacletUploadCloudObjectRouteExport*)



pacletUploadCloudObjectRouteExport[url_, perms_, v_]:=
  With[{
    co=
      pacletUploadBuildPacletCloudObject[url,
        perms,
        v
        ],
    fil=
      Replace[v,
        Rule[_,f_]:>f
        ]
    },
    Take[#, 1]&@
      If[
        Switch[v,
          _File|_String,
            FileExistsQ@v,
          _URL,
            False,
          _Rule,
            FileExistsQ@Last@v
          ],
        CopyFile[
          If[MatchQ[v,_Rule],Last@v,v],
          co],
        CloudDeploy[
          HTTPRedirect@
            If[MatchQ[v,_Rule],
              Last@v,
              v],
          co]
        ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*pacletUpload*)



PacletUpload::nosite="Site `` isn't a string";
Options[pacletUpload]=
  DeleteDuplicatesBy[First]@
    Join[
      Options[PacletSiteURL],
      {
        "BuildRoot":>$PacletBuildRoot,
        "SiteFile"->Automatic,
        "OverwriteSiteFile"->False,
        "UploadSiteFile"->False,
        "UploadInstaller"->False,
        "UploadInstallLink"->False,
        "UploadUninstaller"->False,
        "UseCachedPaclets"->True,
        Permissions->Automatic
        }
      ];
pacletUpload[
  pacletSpecs:$PacletUploadPatterns,
  ops:OptionsPattern[]
  ]:=
  PackageExceptionBlock["PacletTools"]@
  DeleteCases[Nothing]@
  Module[
    {
      bPFFOps=FilterRules[{ops}, Options[PacletFindBuiltFile]],
      base,
      site,
      pacletFiles,
      pacletMZ
      },
    base=
      If[StringQ[#]&&MatchQ[URLParse[#, "Scheme"], "http"|"https"],
        Quiet@
          Check[CloudObject@#, #],
        #
        ]&@
        pacletStandardServerBase@OptionValue["ServerBase"];
    site=
      PacletSiteURL[
        FilterRules[{
          ops
          },
          Options@PacletSiteURL
          ]
        ];
    pacletFiles=
      PacletFindBuiltFile[#,bPFFOps]&/@Flatten@{pacletSpecs};
    If[MatchQ[site,Except[_String]],
      PackageRaiseException[
        Automatic,
        PacletUpload::nosite,
        site
        ]
      ];
    pacletMZ=
      If[OptionValue["UploadSiteFile"]//TrueQ,
        Replace[OptionValue["SiteFile"],
          Automatic:>
            PacletSiteBundle[
              Replace[pacletFiles,
                (k_->_):>k
                ],
              FilterRules[
                {
                  ops,
                  "MergePacletInfo"->
                    If[OptionValue["OverwriteSiteFile"]//TrueQ,
                      None,
                      site
                      ]
                    },
                Options@PacletSiteBundle
                ]
              ]
          ]
        ];
    Switch[base,
      (* ------------------- Wolfram Cloud Paclets ------------------- *)
      "Cloud"|CloudObject|CloudDirectory|Automatic|_CloudObject|_CloudDirectory,
        With[{url=site},
          pacletUploadPostProcess[
            OptionValue["UploadInstallLink"],
            site, 
            OptionValue["Permissions"]
            ]@
          <|
            "PacletSiteFile"->
              If[OptionValue["UploadSiteFile"]//TrueQ,
                Replace[
                  PacletSiteUpload[CloudObject@site,pacletMZ,
                    FilterRules[{ops},Options@PacletSiteUpload]
                    ],
                  _PacletSiteUpload->$Failed
                  ],
                Nothing
                ],
            "PacletFiles"->
              Map[
                pacletUploadCloudObjectRouteExport[url, OptionValue[Permissions], #]&,
                pacletFiles
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
                ]
            |>  
          ],
      _?SyncPathQ,
        With[{p=SyncPath@base},
          Quiet@CreateDirectory[p,
            CreateIntermediateDirectories->True];
          PacletUpload[
            pacletFiles,
            "ServerBase"->p,
            ops
            ]
          ],
      _,
        PackageRaiseException[
          Automatic,
          PacletUpload::nobby,
          base
          ]
        ]
    ];


(* ::Subsubsubsection::Closed:: *)
(*Upload  Wrapper*)



PacletUpload//Clear


Options[PacletUpload]=
  Options[pacletUpload];
PacletUpload::nobby="Unkown site base ``"
PacletUpload::nopac="Unable to find paclet files ``";
PacletUpload[
  pacletSpecs:$PacletUploadPatterns,
  ops:OptionsPattern[]
  ]:=
  PackageExceptionBlock["PacletTools"]@
  Block[
    {
      $PacletBuildRoot=OptionValue["BuildRoot"],
      bPFFOps=FilterRules[{ops},Options[PacletFindBuiltFile]],
      files
      },
    files=PacletFindBuiltFile[#,bPFFOps]&/@Flatten[{pacletSpecs}, 1];
    If[!AllTrue[files,builtPacletFileQ],
      PackageRaiseException[
        Automatic,
        PacletUpload::nopac,
        Pick[Flatten@{pacletSpecs},MatchQ[None|(_->None)]/@files]
        ]
      ];
    If[AllTrue[files, builtPacletFileQ],
      pacletUpload[pacletSpecs,ops],
      PackageRaiseException[Automatic,
        "files `` aren't all built paclets",
        files
        ]
      ]
    ];


(* ::Subsection:: *)
(*Remove*)



(* ::Subsubsection::Closed:: *)
(*pacletRemove*)



pacletRemove[server_,siteExpr_,{name_,version_}]:=
  With[{
    file=
      StringReplace[
        URLBuild@{server,"Paclets",name<>"-"<>version<>".paclet"},{
        "file://"->"file://",
        "file:"->"file://"
        }]
    },
    If[URLParse[file,"Scheme"]==="file",
      Quiet[DeleteFile@FileNameJoin@URLParse[file,"Path"],DeleteFile::nffil],
      Quiet[DeleteFile@CloudObject[file],DeleteFile::nffil]
      ];
    Select[siteExpr,
      !AllTrue[
        Transpose@{
          Lookup[List@@#,{"Name","Version"}],
          {name,version}
          },
        StringMatchQ[#[[1]],#[[2]]]&
        ]&
      ]
    ];
pacletRemove[server_,siteExpr_,fileExt_String?(StringEndsQ[".paclet"])]:=
  pacletRemove[server,siteExpr,
    ReplacePart[#,-1->StringTrim[Last@#,".paclet"]]&@
      StringSplit[fileExt,"-"]
    ];
pacletRemove[server_,siteExpr_,pacName_String]:=
  pacletRemove[server,siteExpr,
    Select[siteExpr,
      StringMatchQ[Lookup[List@@#,"Name"],pacName]&
      ]
    ];
pacletRemove[server_,siteExpr_,pac_PacletManager`Paclet]:=
  pacletRemove[server,siteExpr,
    Lookup[List@@pac,{"Name","Version"}]
    ];
pacletRemove[server_,siteExpr_,pacSpecs_List]:=
  Fold[
    Replace[pacletRemove[server,#,#2],
      _pacletRemove->#
      ]&,
    siteExpr,
    pacSpecs
    ];
pacletRemove[server_,siteExpr_,PacletManager`PacletSite[pacSpecs___]]:=
  pacletRemove[server,siteExpr,{pacSpecs}]


(* ::Subsubsection::Closed:: *)
(*PacletRemove*)



$PacletRemoveSpec:=
  PacletExecuteSettingsLookup[
    "RemovePattern",
    {_String,_String}|PacletManager`Paclet|_String
    ];
$PacletRemovePatterns:=
  $PacletRemoveSpec|{$PacletRemoveSpec..}


Options[PacletRemove]=
  DeleteDuplicatesBy[First]@
  Join[
    Options[PacletSiteURL],
    Options[PacletSiteUpload],
    {
      "OverwriteSiteFile"->True
      }
    ];
PacletRemove[pacSpecs:$PacletRemovePatterns,ops:OptionsPattern[]]:=
  With[{site=PacletSiteURL[FilterRules[{ops},Options@PacletSiteURL]]},
    With[{res=
      Replace[
        pacletRemove[
          site,
          PacletSiteInfo[site],
          pacSpecs
          ],{
        p_PacletManager`PacletSite?(OptionValue["OverwriteSiteFile"]&):>
          PacletSiteUpload[site,
            p,
            FilterRules[
              {
                ops,
                "MergePacletInfo"->False
                },
              Options@PacletSiteUpload
              ]
            ]
        }]
      },
      res/;!MatchQ[res,_pacletRemove]
      ]
    ]


(* ::Subsection:: *)
(*Install*)



$PackageDependenciesFile=
  "DependencyInfo.m";


PacletDownloadPaclet::nopac="Couldn't find paclet at ``";
PacletDownloadPaclet::howdo="Unsure how to pack a paclet from file type ``";
PacletDownloadPaclet::laywha="Couldn't detect package layout from directory ``";
PacletDownloadPaclet::dumcode="Couldn't generate PacletInfo.m for directory ``";
PacletDownloadPaclet::badbun="Not a real directory ``";
PacletDownloadPaclet::badgh="Couldn't download paclet at `` from GitHub";
PacletDownloadPaclet::norem="Couldn't find remote paclet `` on server";


(* ::Subsubsection::Closed:: *)
(*installPacletGenerate*)



Options[installPacletGenerate]={
  "Verbose"->False
  };


(* ::Subsubsubsection::Closed:: *)
(*Directory*)



installPacletGenerate[dir:(_String|_File)?DirectoryQ,ops:OptionsPattern[]]:=
  Block[{bundleDir=dir},
    If[OptionValue@"Verbose",
      DisplayTemporary@
        Internal`LoadingPanel[
          TemplateApply["Bundling paclet for ``",dir]
          ]
        ];
    (* ------------ Extract Archive Files --------------- *)
    If[FileExistsQ@#,Quiet@ExtractArchive[#,dir]]&/@
      Map[
        FileNameJoin@{dir,FileBaseName@dir<>#}&,
        {".zip",".gz"}
        ];
    (* ------------ Detect Paclet Layout --------------- *)
    Which[
      FileExistsQ@FileNameJoin@{dir,"PacletInfo.m"},
        bundleDir=dir,
      FileExistsQ@FileNameJoin@{dir,FileBaseName[dir]<>".m"}||
        FileExistsQ@FileNameJoin@{dir,FileBaseName[dir]<>".wl"}||
        FileExistsQ@FileNameJoin@{dir,"Kernel","init"<>".m"}||
        FileExistsQ@FileNameJoin@{dir,"Kernel","init"<>".wl"},
        bundleDir=dir;
        PacletInfoExpressionBundle[bundleDir],
      FileExistsQ@FileNameJoin@{dir,FileBaseName@dir,"PacletInfo.m"},
        bundleDir=FileNameJoin@{dir,FileBaseName@dir},
      FileExistsQ@FileNameJoin@{dir,FileBaseName@dir,FileBaseName@dir<>".m"},
        bundleDir=FileNameJoin@{dir,FileBaseName@dir};
        PacletInfoExpressionBundle[bundleDir],
      FileExistsQ@FileNameJoin@{dir,FileBaseName[dir]<>".nb"},
        Export[
          FileNameJoin@{dir,FileBaseName[dir]<>".m"};
          "(*Open package notebook*)
CreateDocument[
	Import@
		StringReplace[$InputFileName,\".m\"->\".nb\"]
	]",
          "Text"
          ];
        bundleDir=dir;
        PacletInfoExpressionBundle[bundleDir],
      _,
        PackageRaiseException[
          Automatic,
          PacletInstallPaclet::laywha,
          bundleDir
          ]
      ];
    Which[
      !DirectoryQ@bundleDir,
        PackageRaiseException[
          Automatic,
          PacletInstallPaclet::badbun,
          bundleDir
          ],
      !FileExistsQ@FileNameJoin@{bundleDir, "PacletInfo.m"},
        PackageRaiseException[
          Automatic,
          PacletInstallPaclet::dumcode,
          bundleDir
          ],
      True,
        PacletBundle[bundleDir]
      ]
    ];


(* ::Subsubsubsection::Closed:: *)
(*File*)



installPacletGenerate[file:(_String|_File)?FileExistsQ,ops:OptionsPattern[]]:=
  Switch[FileExtension[file],
    "m"|"wl",
      If[OptionValue@"Verbose",
        DisplayTemporary@
          Internal`LoadingPanel[
            TemplateApply["Bundling paclet for ``",file]
            ]
          ];
      With[{dir=
        FileNameJoin@{
          $TemporaryDirectory,
          FileBaseName@file
          }
        },
        If[!DirectoryQ@dir,
          CreateDirectory[dir]
          ];
        If[FileExistsQ@
          FileNameJoin@{
            DirectoryName@file,
            $PackageDependenciesFile
            },
          CopyFile[
            FileNameJoin@{
              DirectoryName@file,
              $PackageDependenciesFile
              },
            FileNameJoin@{
              dir,
              $PackageDependenciesFile
              }  
            ]
          ];
        If[FileExistsQ@
          FileNameJoin@{
            DirectoryName@file,
            "PacletInfo.m"
            },
          CopyFile[
            FileNameJoin@{
              DirectoryName@file,
              "PacletInfo.m"
              },
            FileNameJoin@{
              dir,
              "PacletInfo.m"
              }  
            ]
          ];
        CopyFile[file,
          FileNameJoin@{
            dir,
            FileNameTake@file
            },
          OverwriteTarget->True
          ];
        PacletInfoExpressionBundle[dir,
          "Name"->
            StringReplace[FileBaseName[dir],
              Except[WordCharacter|"$"]->""]
              ];
        PacletBundle[dir,
          "BuildRoot"->$TemporaryDirectory
          ]
        ],
    "nb",
      With[{dir=
        FileNameJoin@{
          $TemporaryDirectory,
          StringJoin@RandomSample[Alphabet[],10],
          FileBaseName@file
          }
          },
        Quiet[
          DeleteDirectory[dir,DeleteContents->True];
          CreateDirectory[dir,CreateIntermediateDirectories->True]
          ];
        CopyFile[file,FileNameJoin@{dir,FileNameTake@file}];
        installPacletGenerate[dir]
        ],
    "paclet",
      file,
    _,
      Message[PacletInstallPaclet::howdo,
        FileExtension@file
        ]
    ];


(* ::Subsubsection::Closed:: *)
(*gitPacletPull*)



gitPacletPull//Clear


gitPacletPull[loc:(_String|_File|_URL)?GitHubPathQ]:=
  GitHub["Clone", loc, OverwriteTarget->True];
gitPacletPull[loc:(_String|_File|_URL)?(Not@*GitHubPathQ)]:=
  Git["Clone", loc, OverwriteTarget->True];


(* ::Subsubsection::Closed:: *)
(*wolframLibraryPull*)



wolframLibraryPull[loc:_String|_URL]:=
  With[{fileURLs=
    URLBuild@
      Merge[{
          URLParse[loc],
          URLParse[#]
          },
        Replace[DeleteCases[#,None],{
            {s_}:>s,
            {___,l_}:>l,
            {}->None
            }]&
        ]&/@
      Cases[
        Import[loc,{"HTML","XMLObject"}],
        XMLElement["a",
          {
            ___,
            "href"->link_,
            ___},
          {___,
            XMLElement["img",
              {___,"src"->"/images/database/download-icon.gif",___},
              _],
            ___}
          ]:>link,
        \[Infinity]
        ]
    },
    With[{name=
      FileBaseName@
        First@
          SortBy[
            Switch[FileExtension[#],
              "paclet",
                0,
              "zip"|"gz",
                1,
              "wl"|"m",
                2,
              _,
                3
              ]&
            ][URLParse[#,"Path"][[-1]]&/@fileURLs]
        },
      Quiet@
        DeleteDirectory[
          FileNameJoin@{$TemporaryDirectory,name},
          DeleteContents->True
          ];
      CreateDirectory@FileNameJoin@{$TemporaryDirectory,name};
      MapThread[
        RenameFile[
          #,
          FileNameJoin@{$TemporaryDirectory,name,URLParse[#2,"Path"][[-1]]}
          ]&,{
        URLDownload[fileURLs,
          FileNameJoin@{$TemporaryDirectory,name}],
        fileURLs
        }];
      FileNameJoin@{$TemporaryDirectory,name}
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*downloadURLIfExists*)



downloadURLIfExists[urlBase_,{files__},dir_]:=
  If[
    MatchQ[0|200]@
      URLSave[
        URLBuild@{urlBase,#},
        FileNameJoin@{
          dir,
          #
          },
        "StatusCode"
        ],
    FileNameJoin@{
      dir,
      #
      },
    Quiet@
      DeleteFile@
        FileNameJoin@{
          dir,
          #
          };
    Nothing
    ]&/@{files}


(* ::Subsubsection::Closed:: *)
(*pacletSiteDownload*)



Options[pacletDownloadFromSite]=
  Append[
    Options[PacletManager`PacletFindRemote],
    "Site"->None
    ];
pacletDownloadFromSite[
  paclet_,
  ops:OptionsPattern[]
  ]:=
  Block[
    {
      pfrData,
      fromSite=OptionValue["Site"],
      newSiteQ,
      pacToLoad,
      pacFile,
      targetFile
      },
    Internal`WithLocalSettings[
      If[StringQ@fromSite,
        newSiteQ=
          !MemberQ[PacletManager`PacletSites[], PacletManager`PacletSite[fromSite,__]];
        If[newSiteQ, 
          PacletManager`PacletSiteAdd@fromSite;
          PacletManager`PacletSiteUpdate@fromSite;
          ]
        ],
      pfrData=
        PacletManager`PacletFindRemote[paclet, 
          FilterRules[{ops}, Options@PacletManager`PacletFindRemote]
          ];
      If[Length@pfrData==0,
        Message[PacletDownloadPaclet::norem, paclet];
        $Failed,
        pacToLoad=pfrData[[1]];
        targetFile=
          FileNameJoin@{
            $TemporaryDirectory, 
            pacToLoad["Name"]<>"-"<>pacToLoad["Version"]<>".paclet"
            };
        pacFile=
          URLDownload[
            URLBuild@
              {
                pacToLoad["Location"], 
                "Paclets", 
                FileNameTake[targetFile]
                },
            targetFile
            ];
        Replace[
          pacFile,
          File[p_]:>p
          ]
        ],
      If[newSiteQ, 
        PacletManager`PacletSiteRemove@fromSite;
        ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*PacletDownloadPaclet*)



PacletDownloadPaclet//Clear


Options[PacletDownloadPaclet]=
  Join[
    {
      "Verbose"->True,
      "Log"->True
      },
    Options[pacletDownloadFromSite]
    ]


(* ::Subsubsubsection::Closed:: *)
(*Server*)



pacletDownloadVersionPattern=
  DigitCharacter~~(DigitCharacter|".")...;
pacletDownloadNamePattern=
  (WordCharacter|"_")..~~
    (""|("-"~~pacletDownloadVersionPattern));


PacletDownloadPaclet[
  pacletName:
    _String?(StringMatchQ[pacletDownloadNamePattern])|
    {
      _String?(StringMatchQ[(WordCharacter|"_")..]), 
      _String?(StringMatchQ[pacletDownloadVersionPattern])
      },
  ops:OptionsPattern[]
  ]:=
  With[
    {
      pname=
        If[ListQ@pacletName, pacletName[[1]], 
          StringSplit[pacletName, "-"][[1]]
          ],
      pvers=
        If[ListQ@pacletName, 
          pacletName[[2]], 
          Replace[StringSplit[pacletName, "-"],
            {
              {_, v_}:>v,
              {_}:>None
              }
            ]
          ]
      },
    If[OptionValue["Verbose"],
      Function[Null, 
        Monitor[
          #,
          Internal`LoadingPanel@
            TemplateApply[
              "Downloading paclet `` from server",
              pname
              ]
          ], 
        HoldAll
        ],
      Identity
      ]@
      pacletDownloadFromSite[
        If[pvers===None,
          pname,
          {pname, pvers}
          ],
        FilterRules[{ops},
          Options[pacletDownloadFromSite]
          ]
        ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*Directory*)



PacletDownloadPaclet[
  loc:(_String|_File)?FileExistsQ,
  ops:OptionsPattern[]
  ]:=
  installPacletGenerate[loc, ops];


(* ::Subsubsubsection::Closed:: *)
(*URL*)



PacletDownloadPaclet[
  loc:(_String?(URLParse[#,"Scheme"]=!=None&)|_URL),
  ops:OptionsPattern[]
  ]:=
  Which[
    URLParse[loc, "Domain"]==="github.com"||
    URLParse[loc, "Scheme"]=="github"||
    URLParse[loc, "Scheme"]=="github-release",
      With[{dir=
        If[!FileExistsQ@#, 
          Message[PacletDownloadPaclet::badgh, loc];
          $Failed,
          If[Head[#]===File, #[[1]], #]
          ]&@
          If[OptionValue@"Verbose"//TrueQ,
            Monitor[
              gitPacletPull[loc],
              Which[
                (StringQ@loc&&StringStartsQ[loc, "github-release"])||
                  GitHubReleaseQ@loc,
                    Internal`LoadingPanel[
                      TemplateApply["Pulling release at ``",loc]
                      ],
                GitHubRepoQ@loc,
                  Internal`LoadingPanel[
                    TemplateApply["Cloning repository at ``",loc]
                    ],
                True,
                  Internal`LoadingPanel[
                    TemplateApply["Downloading from ``",loc]
                    ]
                ]
              ],
            gitPacletPull[loc]
            ]
        },
        PacletDownloadPaclet@dir
        ],
      URLParse[loc,"Domain"]==="library.wolfram.com",
        With[{dir=
          If[OptionValue@"Verbose"//TrueQ,
            Monitor[
              wolframLibraryPull[loc],
              Internal`LoadingPanel[
                TemplateApply["Downloading from library.wolfram.com ``",loc]
                ]
              ],
            gitPacletPull[loc]
            ]
          },
          PacletDownloadPaclet@dir
          ],
      True,
        Switch[
          URLParse[loc,"Path"][[-1]],
          _?(FileExtension[#]=="paclet"&),
            URLDownload[loc],
          _?(MatchQ[FileExtension[#], "m"|"wl"]&),
            PacletDownloadPaclet@
              downloadURLIfExists[
                URLBuild[
                  ReplacePart[#,
                    "Path"->
                      Drop[#Path,-1]
                    ]&@URLParse[loc]
                  ],
                {
                  URLParse[loc,"Path"][[-1]],
                  $PackageDependenciesFile,
                  "PacletInfo.m"
                  }
                ],
          _,
            Message[PacletDownloadPaclet::nopac, loc];
            $Failed
            (*Replace[
					Quiet@Normal@PacletSiteInfoDataset[loc],
					{
						Except[{__Association}]:>
							(
								Message[PacletDownloadPaclet::nopac, loc];
								$Failed
								),
						a:{__Association}:>
							PacletDownloadPaclet[
								URLBuild@
									Flatten@{
										loc,
										StringJoin@{
											Lookup[Last@SortBy[a, #Version&],{
												"Name",
												"Version"
												}],
											".paclet"
											}
										},
								ops
								]
						}
					]*)
          ]
      ];


(* ::Subsubsection::Closed:: *)
(*InstallDeps*)



PacletInstallProcessDependencies[p_, deps_, ops___]:=
  If[MatchQ[deps,_List|All],
      Flatten@{
        p,
        With[{l=PacletLookup[p, "Location"]},
          If[FileExistsQ@FileNameJoin@{l, $PackageDependenciesFile},
            Replace[
              Import[FileNameJoin@{l, $PackageDependenciesFile}],
              {
                a_Association:>
                  Switch[deps,
                    All,
                      Flatten@
                        Map[
                          Map[PacletInstallPaclet[#, ops]&, #]&, 
                          a
                          ],
                    _,
                      Flatten@
                        Map[
                          PacletInstallPaclet[#, ops]&,
                          Flatten@Lookup[a, deps, {}]
                          ]
                    ],
                l_List:>
                  Map[PacletInstallPaclet[#, ops]&,l],
                _->
                  {}
                }
              ],
            {}
            ]
          ]
        },
      p
      ]


(* ::Subsubsection::Closed:: *)
(*PacletInstallPaclet*)



Options[PacletInstallPaclet]=
  {
    "Verbose"->True,
    "InstallSite"->True,
    "InstallDependencies"->
      Automatic,
    "Log"->True
    };
PacletInstallPaclet[
  loc:
    (_String|_File)?FileExistsQ|
    (_String?(URLParse[#,"Scheme"]=!=None&)|_URL),
  ops:OptionsPattern[]
  ]:=
  PackageExceptionBlock["PacletTools"]@
    If[
      And[
        OptionValue["InstallSite"]//TrueQ,
        MatchQ[
          Quiet@PacletSiteInfo[loc],
          PacletManager`PacletSite[__PacletManager`Paclet]
          ]
        ],
      PacletSiteInstall[loc],
        Replace[
          PacletDownloadPaclet[loc, FilterRules[{ops}, Options[PacletDownloadPaclet]]],
          {
            File[f_]|(f_String?FileExistsQ):>
              Replace[PacletManager`PacletInstall@f,
                p_PacletManager`Paclet:>
                  With[{deps=
                    Replace[OptionValue["InstallDependencies"],
                      {
                        Automatic->{"Standard"},
                        True->All
                        }
                      ]
                    },
                    PacletInstallProcessDependencies[p, deps, ops]
                    ]
                ],
            _->$Failed
            }
          ]
        ];


(* ::Subsection:: *)
(*Format*)



If[!AssociationQ@$pacletIconCache, $pacletIconCache=<||>];
pacletGetIcon[a_]:=
  Replace[
    If[StringQ@a["Location"]&&StringLength[a["Location"]]>0,
      FileNames[
        Lookup[
          a,
          "Thumbnail",
          Lookup[
            a,
            "Icon",
            "PacletIcon.m"|"PacletIcon.png"
            ]
          ],
        a["Location"]
        ],
      {}
      ],
    {
      {f_, ___}:>
        Replace[
          Lookup[$pacletIconCache, f, $pacletIconCache[f] = Import[f]],
          i_?ImageQ:>Image[i, ImageSize->28]
          ],
      {}:>
        With[{f=PackageFilePath["Resources", "Icons", "PacletIcon.png"]},
          Image[
            Lookup[$pacletIconCache, f, $pacletIconCache[f] = Import[f]],
            ImageSize->28
            ]
          ]
        (*Pane[
					Style[Last@StringSplit[a["Name"],"_"],"Input"],
					{Automatic,28},
					Alignment\[Rule]Center
					]*)
      }
    ];      


pacletSiteIcon[_]:=
  With[{f=PackageFilePath["Resources", "Icons", "PacletSiteIcon.png"]},
      Image[
        Lookup[$pacletIconCache, f, $pacletIconCache[f] = Import[f]],
        ImageSize->28
        ]
      ]


pacletGetDocsLink[a_]:=
  "paclet:"<>
    StringReplace[a["Name"], 
      {
        "ServiceConnection_"->"ref/service",
        "Documentation_"~~n__:>n
        }
      ]


pacletMakeSummaryItem[k_, v_]:=
  BoxForm`MakeSummaryItem[
    {Row[{k, ": "}], Short@v},
    StandardForm
    ]


pacletSummaryDynamic[expr_, a_]:=
  Dynamic[Refresh[expr, None], TrackedSymbols:>{}, UpdateInterval->Infinity]/.
    Key[k_String]:>RuleCondition[a[k], True];
pacletSummaryDynamic~SetAttributes~HoldFirst;


validPacletToFormat[p_]:=
  MatchQ[p, PacletManager`Paclet[__Rule]]&&
    StringQ@p["Name"]


SetPacletFormatting[]:=
  (
    If[!BooleanQ@$FormatPaclets, $FormatPaclets=True];
    Format[p_PacletManager`Paclet/;
      ($FormatPaclets&&validPacletToFormat[p])]:=
      With[{a=PacletInfoAssociation[p]},
      RawBoxes@
        BoxForm`ArrangeSummaryBox[
          "Paclet",
          p,
          pacletGetIcon[a],
          {
            pacletMakeSummaryItem["Name",
              With[{dl=pacletGetDocsLink[a], n=a["Name"]},
                pacletSummaryDynamic[
                  If[StringQ@Documentation`ResolveLink[dl],
                    Hyperlink[Key["Name"], dl],
                    Key["Name"]
                    ],
                  a
                  ]
                ]
              ],
            pacletMakeSummaryItem["Version", a["Version"]]
            },
          Join[
            {
              If[StringQ[a["Location"]]&&DirectoryQ@a["Location"],
                pacletMakeSummaryItem["Location",
                  With[{l=a["Location"]},
                    Button[
                      Hyperlink[l],
                      SystemOpen[l],
                      Appearance->None,
                      BaseStyle->"Hyperlink"
                      ]
                    ]
                  ],
                pacletMakeSummaryItem[
                  "Installed",
                  pacletSummaryDynamic[
                    If[PacletInstalledQ[{Key["Name"], Key["Version"]}],
                      True,
                      If[PacletExistsQ[{Key["Name"], Key["Version"]}],
                        Button[
                          Mouseover[
                            Style["Click to install", "Hyperlink"],
                            Style["Click to install", "HyperlinkActive"]
                            ],
                          PacletInstall[Key["Name"]],
                          Appearance->None,
                          BaseStyle->"Hyperlink",
                          Method->"Queued"
                          ],
                        False
                        ]
                      ],
                    a
                    ]
                  ]
                ],
              If[KeyMemberQ[a,"URL"],
                pacletMakeSummaryItem["URL",
                  Hyperlink[a["URL"]]
                  ],
                Nothing
                ]
              },
            KeyValueMap[
              pacletMakeSummaryItem,
              KeyDrop[a,
                {
                  "Name", "Version", 
                  "Location", "URL", 
                  "Extensions"
                  }
                ]
              ],
            Sequence@@KeyValueMap[
              With[{k=#, asso=#2},
                KeyValueMap[
                  pacletMakeSummaryItem,
                  KeyMap[k<>#&, KeySelect[asso, StringQ]]
                  ]
                ]&,
              Lookup[a, "Extensions", <||>]
              ]
            ],
          StandardForm
          ]
        ];
    Format[site:PacletManager`PacletSite[p__PacletManager`Paclet]/;
      ($FormatPaclets&&AllTrue[{p}, validPacletToFormat])]:=
      With[{a=PacletLookup[{p}, {"Name", "Version"}]},
        RawBoxes@
          BoxForm`ArrangeSummaryBox[
            "PacletSite",
            site,
            pacletSiteIcon[site],
            {
              pacletMakeSummaryItem[
                "Paclets",
                Short@
                  Map[
                    StringRiffle[#, "-"]&,
                    a
                    ]
                ]
              },
            {
              },
            StandardForm
            ]
        ];
    FormatValues[PacletManager`Paclet]=
      SortBy[
        FormatValues[PacletManager`Paclet],
        FreeQ[HoldPattern[$FormatPaclets]]
        ];
    );
If[$TopLevelLoad, SetPacletFormatting[]]


End[];




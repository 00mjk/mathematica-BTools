(* ::Package:: *)

(* Autogenerated Package *)

(* ::Text:: *)
(*Internal docs cruft that\[CloseCurlyQuote]s been pushed to a lower-context*)



(* ::Subsubsection::Closed:: *)
(*Docs*)



AppIndexDocs::usage=
  "Indexes the doc pages of an app";
AppGenerateSymbolNotebook::usage=
  "";
AppSymbolNotebook::usage=
  "Generates a doc template for an app";
AppGeneratePackageSymbolNotebook::usage=
  "";
AppPackageSymbolNotebook::usage=
  "Generates a doc template for a package";
AppGuideNotebook::usage=
  "Generates a guide overview for the app";
AppPackageGuideNotebook::usage=
  "Generates a guide overview for a package";
AppTutorialNotebook::usage=
  "Generates a tutorial overview for the app";
AppDocumentationTemplate::usage=
  "Creates a total documentation template for an app";
AppSaveSymbolPages::usage=
  "Saves auto-generated symbol pages";
AppPackageSaveSymbolPages::usage=
  "Saves auto-generated symbol pages for a package";
AppSaveGuide::usage=
  "Saves an auto-generated guide for an app";
AppPackageSaveGuide::usage=
  "Saves auto-generated guide for a package";
AppGenerateDocumentation::usage=
  "Generates symbol pages and guide page for an app";
AppPackageGenerateDocumentation::usage=
  "Generates symbol pages and guide page for a package";
AppGenerateHTMLDocumentation::usage=
  "Generates HTML documentation for an app";


Begin["`Private`"];


(* ::Subsection:: *)
(*Docs*)



(* ::Subsubsection::Closed:: *)
(*DocInfo*)



Options[AppRegenerateDocInfo]=
  Options@DocContextTemplate;
AppRegenerateDocInfo[app_String,ops:OptionsPattern[]]:=
  Export[AppPath[app,"Config","DocInfo.m"],
    Flatten@{
      ops,
      "Usage"->Automatic,
      "Functions"->Automatic,
      "Details"->Automatic,
      "Examples"->Defer,
      "RelatedLinks"->None,
      "GuideOptions"->{},
      "TutorialOptions"->{}
      }
    ];


(* ::Subsubsection::Closed:: *)
(*AppIndexDocs*)



AppIndexDocs[app_,lang:_String:"English"]:=
  DocGen[
    "Index",
    AppPath[app,"Documentation",lang]
    ];


(* ::Subsubsection::Closed:: *)
(*AppSymbolNotebook*)



Options[AppSymbolNotebook]=
  Prepend["DocInfo"->Automatic]@
    Options@SymbolPageTemplate;
AppSymbolNotebook[app_, ops:OptionsPattern[]]:=
  Replace[OptionValue@"DocInfo",{
    Automatic:>
      AppSymbolNotebook[app,
        "DocInfo"->
          AppPath[app,
            "Config",
            "DocInfo.m"],
        ops],
    f_String?FileExistsQ:>
      AppSymbolNotebook[app,
        "DocInfo"->None,
        ops,
        Sequence@@
          FilterRules[
            DeleteCases[Import[f],
                Alternatives@@Options@AppSymbolNotebook],
            Options@AppSymbolNotebook
            ]
          ],
    e_:>
      With[{fs=AppPackageFunctions[app]},
        Notebook[
          Flatten@{
            Cell[app<>" Documentation Template","Title"],
            Cell[BoxData@RowBox@{"<<",app<>"`"},
              "Input"],
            Cell[BoxData@RowBox@{"$DocActive","=","\""<>app<>"\"",";"},
              "Input"],
            Cell["","BlockSeparator"],
            First/@#
            },
          Sequence@@Rest@First@#
          ]&@
          KeyValueMap[
            SymbolPageTemplate[#2,
              Sequence@@FilterRules[{ops},
                Options@SymbolPageTemplate],
              "Usage"->Automatic,
              "Details"->Automatic,
              "Functions"->#2,
              "Examples"->Defer,
              "RelatedGuides"->{
                app<>" Overview"->app,
                #<>" Package"->#<>"Package"
                },
              "RelatedTutorials"->{
                app<>" Tutorial"
                },
              "RelatedLinks"->None
              ]&,
            fs
            ]
        ]
    }];


(* ::Subsubsection::Closed:: *)
(*AppGenerateSymbolNotebook*)



Options[AppGenerateSymbolNotebook]=
  Options@AppSymbolNotebook;
AppGenerateSymbolNotebook[app_, ops:OptionsPattern[]]:=
  CreateDocument@
    AppSymbolNotebook[app, ops]


(* ::Subsubsection::Closed:: *)
(*AppPackageSymbolNotebook*)



Options[AppPackageSymbolNotebook]=
  Prepend[Options@SymbolPageTemplate,
    "DocInfo"->Automatic
    ];
AppPackageSymbolNotebook[app_,pkg_,ops:OptionsPattern[]]:=
  Replace[OptionValue@"DocInfo",{
    Automatic:>
      AppPackageSymbolNotebook[app,pkg,
        "DocInfo"->
          AppPath[app,
            "Config",
            "DocInfo.m"],
        ops],
    f_String?FileExistsQ:>
      AppPackageSymbolNotebook[app,pkg,
        "DocInfo"->None,
        ops,
        Sequence@@
          FilterRules[
            DeleteCases[Import[f],
                Alternatives@@Options@AppPackageSymbolNotebook],
            Options@AppPackageSymbolNotebook
            ]
          ],
    e_:>
      With[{fs=AppPackageFunctions[app,pkg]},
        Replace[
          SymbolPageTemplate[fs,
            Sequence@@FilterRules[{ops},
              Options@SymbolPageTemplate],
            "Usage"->Automatic,
            "Details"->Automatic,
            "Functions"->fs,
            "Examples"->Defer,
            "RelatedGuides"->{
              app<>" Overview"->app,
              pkg<>" Package"->pkg<>"Package"
              },
            "RelatedTutorials"->{
              app<>" Tutorial"
              },
            "RelatedLinks"->None
            ],
          Notebook[{a__},o___]:>
            Notebook[{
              Cell[app<>" Documentation Template","Title"],
              Cell[BoxData@RowBox@{"<<",app<>"`"},
                "Input"],
              Cell[BoxData@RowBox@{"$DocActive","=","\""<>app<>"\"",";"},
                "Input"],
              Cell["","BlockSeparator"],
              a
              },
              o
              ]
          ]
        ]
    }];


(* ::Subsubsection::Closed:: *)
(*AppGeneratePackageSymbolNotebook*)



Options[AppGeneratePackageSymbolNotebook]=
  Options[AppPackageSymbolNotebook]
AppGeneratePackageSymbolNotebook[app_,pkg_,ops:OptionsPattern[]]:=
  CreateDocument@AppPackageSymbolNotebook[app, pkg, ops]


(* ::Subsubsection::Closed:: *)
(*AppGuideNotebook*)



Options[AppGuideNotebook]=
  Prepend["DocInfo"->Automatic]@
    Options@GuideTemplate;
AppGuideNotebook[app_,ops:OptionsPattern[]]:=
  Replace[OptionValue@"DocInfo",{
    Automatic:>
      AppGuideNotebook[app,
        "DocInfo"->
          AppPath[app,
            "Config",
            "DocInfo.m"],
        ops],
    f_String?FileExistsQ:>
      AppGuideNotebook[app,
        "DocInfo"->None,
        ops,
        Sequence@@
          FilterRules[
            DeleteCases[Lookup[Import[f],"GuideOptions",{}],
                Alternatives@@Options@AppGuideNotebook],
            Options@AppGuideNotebook
            ]
          ],
    e_:>
      With[{fs=AppPackageFunctions[app]},
        GuideTemplate[app,
          Sequence@@FilterRules[{ops},
            Options@GuideTemplate],
          "Title"->app<>" Application Overview",
          "Link"->app,
          "Abstract"->
            TemplateApply[
              "The `` app has `` subpackages and `` top-level functions",{
                app,
                Length@fs,
                Length/@fs//Total
                }],
          "Functions"->
            Flatten[List@@fs],
          "Subsections"->
            KeyValueMap[(#->(#<>"Package"))->#2&]@
              Map[Take[#,UpTo[4]]&,fs],
          "RelatedGuides"->
            Map[#->#<>"Package"&,
              Keys@fs],
          "RelatedTutorials"->
            Flatten@{
              app<>" Tutorial"
              },
          "RelatedLinks"->
            None
          ]//
          Replace[
            Notebook[{a__},o___]:>
              Notebook[{
                Cell[app<>" Documentation","Title"],
                Cell[BoxData@RowBox@{"<<",app<>"`"},
                  "Input"],
                Cell[BoxData@RowBox@{"$DocActive","=","\""<>app<>"\"",";"},
                  "Input"],
                Cell["","BlockSeparator"],
                a
                },
                o
                ]
              
            ]
        ]
  }];


(* ::Subsubsection::Closed:: *)
(*AppPackageGuideNotebook*)



Options[AppPackageGuideNotebook]=
  Prepend["DocInfo"->Automatic]@
    Options@GuideTemplate;
AppPackageGuideNotebook[app_,pkg_,ops:OptionsPattern[]]:=
  Replace[OptionValue@"DocInfo",{
    Automatic:>
      AppPackageGuideNotebook[app,pkg,
        "DocInfo"->
          AppPath[app,
            "Config",
            "DocInfo.m"
            ],
        ops],
    f_String?FileExistsQ:>
      AppPackageGuideNotebook[app,pkg,
        "DocInfo"->None,
        ops,
        Sequence@@
          FilterRules[
            DeleteCases[Lookup[Import[f],"GuideOptions",{}],
                Alternatives@@Options@AppPackageGuideNotebook],
            Options@AppPackageGuideNotebook
            ]
          ],
    e_:>
      With[{fs=AppPackageFunctions[app,pkg]},
        With[{types=
          GroupBy[Keys@#,#]&@SymbolDetermineType[fs]
          },
          GuideTemplate[pkg,
            Sequence@@FilterRules[{ops},Options@GuideTemplate],
            "Title"->pkg<>" Package Overview",
            "Link"->pkg<>"Package",
            "Abstract"->
              guideAutoAbstract[
                TemplateApply[
                  "in the `pkg` package",
                  <|
                    "pkg"->pkg
                    |>
                  ],
                fs,
                types
                ],
            "Functions"->
              fs,
            "Subsections"->
              DeleteCases[Delimiter]@
              Replace[
                guideAutoSubsections[types],
                (f_->l_):>(f->Flatten@l),
                1
                ],
            "RelatedGuides"->
              {
                (app<>" Application Overview")->app
                },
            "RelatedTutorials"->
              Flatten@{
                app<>" Tutorial"
                },
            "RelatedLinks"->
              None
            ]//
            Replace[
              Notebook[{a__},o___]:>
                Notebook[{
                  Cell[app<>" "<>pkg,"Title"],
                  Cell[BoxData@RowBox@{"<<",app<>"`"},
                    "Input"],
                  Cell[BoxData@RowBox@{"$DocActive","=","\""<>app<>"\"",";"},
                    "Input"],
                  Cell["","BlockSeparator"],
                  a
                  },
                  o
                  ]
                
              ]
          ]
        ]
    }];


(* ::Subsubsection::Closed:: *)
(*AppTutorialNotebook*)



Options[AppTutorialNotebook]=
  Prepend["DocInfo"->Automatic]@
    Options@TutorialTemplate;
AppTutorialNotebook[app_,ops:OptionsPattern[]]:=
  Replace[OptionValue@"DocInfo",{
    Automatic:>
      AppTutorialNotebook[app,
        "DocInfo"->
          AppPath[app,
            "Config",
            "DocInfo.m"],
        ops],
    f_String?FileExistsQ:>
      AppTutorialNotebook[app,
        "DocInfo"->None,
        ops,
        Sequence@@
          FilterRules[
            DeleteCases[Lookup[Import[f],"TutorialOptions",{}],
                Alternatives@@Options@AppTutorialNotebook],
            Options@AppTutorialNotebook
            ]
          ],
    e_:>
      With[{fs=AppPackageFunctions[app]},
        TutorialTemplate[app,
          Sequence@@FilterRules[{ops},
            Options@TutorialTemplate],
          "Title"->(app<>" Tutorial"),
          "Description"->
            TemplateApply["Tutorial for the `` application",app],
          "Content"->
            KeyValueMap[
              #->{
                TemplateApply["The `` package has `` functions.",
                  {#,Length@#2}],
                "These are:",
                Thread@{#2}
                }&,
              fs],
          "Functions"->
            Flatten@(Values@fs),
          "RelatedGuides"->
            Prepend[
              Map[#->#<>"PackageGuide"&,
                Keys@fs],
              (app<>" Overview")->app
              ],
          "RelatedTutorials"->
            None,
          "RelatedLinks"->
            None
          ]//
          Replace[
            Notebook[{a__},o___]:>
              Notebook[{
                Cell[app<>" Documentation Template","Title"],
                Cell[BoxData@RowBox@{"<<",app<>"`"},
                  "Input"],
                Cell[BoxData@RowBox@{"$DocActive","=","\""<>app<>"\"",";"},
                  "Input"],
                Cell["","BlockSeparator"],
                a
                },
                o
                ]
              
            ]
        ]
    }];


(* ::Subsubsection::Closed:: *)
(*AppPackageTutorialNotebook*)



Options[AppPackageTutorialNotebook]=
  Prepend["DocInfo"->Automatic]@
    Options@TutorialTemplate;
AppPackageTutorialNotebook[app_, pkg_, ops:OptionsPattern[]]:=
  Replace[OptionValue@"DocInfo",{
    Automatic:>
      AppPackageTutorialNotebook[app,
        "DocInfo"->
          AppPath[app,
            "Config",
            "DocInfo.m"
            ],
        ops],
    f_String?FileExistsQ:>
      AppTutorialNotebook[app,
        "DocInfo"->None,
        ops,
        Sequence@@
          FilterRules[
            DeleteCases[
              Lookup[Import[f],"TutorialOptions",{}],
              Alternatives@@Options@AppTutorialNotebook
              ],
            Options@AppTutorialNotebook
            ]
          ],
    e_:>
      With[{fs=AppPackageFunctions[app, pkg]},
        TutorialTemplate[app,
          Sequence@@FilterRules[{ops},
            Options@TutorialTemplate
            ],
          "Title"->(app<>" "<>pkg<>" Tutorial"),
          "Description"->
            TemplateApply[
              "Tutorial for the `` package in the `` application",
              {pkg, app}
              ],
          "Content"->
            KeyValueMap[
              #->{
                TemplateApply[
                  "The `` package has `` functions.",
                  {pkg, Length@fs}
                  ],
                "These are:",
                Thread@{fs}
                }&,
              fs
              ],
          "Functions"->
            fs,
          "RelatedGuides"->
            Prepend[
              Map[#->#<>"PackageGuide"&, Keys@fs],
              (app<>" Overview")->app
              ],
          "RelatedTutorials"->
            None,
          "RelatedLinks"->
            None
          ]//
          Replace[
            Notebook[{a__},o___]:>
              Notebook[
                {
                  Cell[app<>" Documentation Template","Title"],
                  Cell[BoxData@RowBox@{"<<",app<>"`"}, "Input"],
                  Cell[
                    BoxData@RowBox@
                      {
                        ToBoxes[Unevaluated[$DocActive]],"="," \""<>app<>"\"",";"
                        },
                    "Input"
                    ],
                  Cell["","BlockSeparator"],
                  a
                  },
                o
                ]
            ]
        ]
    }];


(* ::Subsubsection::Closed:: *)
(*AppDocumentationTemplate*)



Options[AppDocumentationTemplate]=
  Join[
    Options[AppSymbolNotebook],
    Options[AppGuideNotebook],
    Options[AppTutorialNotebook]
    ];
AppDocumentationTemplate[app_, ops:OptionsPattern[]]:=
  With[{docs=AppSymbolNotebook[app, FilterRules[{ops}, Options@AppSymbolNotebook]]},
    Notebook[
      Flatten@
        {
          Cell[app<>" Documentation Template","Title"],
          Cell[BoxData@RowBox@{"<<",app<>"`"},"Input"],
          Cell[BoxData@ToBoxes@Unevaluated[$DocActive=app;],
            "Input"
            ],
          Cell["","BlockSeparator"],
          Cell[app<>" Ref Pages","Chapter"],
          First@docs,
          Cell[app<>" Guide Pages","Chapter"],
          First@AppGuideNotebook[app, FilterRules[{ops}, Options@AppGuideNotebook]],
          Map[
            First@AppPackageGuideNotebook[app,#]&,
            FileBaseName/@AppPackages[app]
            ],
          Cell[app<>" Tutorial Page","Chapter"],
          First@AppTutorialNotebook[app, FilterRules[{ops}, Options@AppTutorialNotebook]]
          },
      Sequence@@Rest@docs
      ]
  ]


(* ::Subsubsection::Closed:: *)
(*AppPackageDocumentationTemplate*)



Options[AppPackageDocumentationTemplate]=
  Join[
    Options[AppPackageSymbolNotebook],
    Options[AppPackageGuideNotebook],
    Options[AppPackageTutorialNotebook]
    ];
AppPackageDocumentationTemplate[app_, pkg_, ops:OptionsPattern[]]:=
  With[
    {
      docs=AppPackageSymbolNotebook[app, FilterRules[{ops}, Options@AppSymbolNotebook]]
      },
    Notebook[
      Flatten@
        {
          Cell[app " "<>pkg<>" Package Template","Title"],
          Cell[BoxData@RowBox@{"<<",app<>"`"},"Input"],
          Cell[BoxData@ToBoxes@Unevaluated[$DocActive=app;],
            "Input"
            ],
          Cell["","BlockSeparator"],
          Cell[app<>" "<>pkg<>" Package Ref Pages","Chapter"],
          First@docs,
          Cell[app<>" "<>pkg<>" Package Guide Pages","Chapter"],
          First@
            AppPackageGuideNotebook[app, pkg,
              FilterRules[{ops}, Options@AppPackageGuideNotebook]],
          Cell[app<>" "<>pkg<>" Package Tutorial","Chapter"],
          First@
            AppPackageTutorialNotebook[app, pkg,
              FilterRules[{ops}, Options@AppPackageTutorialNotebook]]
          },
      Sequence@@Rest@docs
      ]
  ]


(* ::Subsubsection::Closed:: *)
(*AppSaveSymbolPages*)



Options[AppSaveSymbolPages]=
  Join[
    Options[AppPackageSymbolNotebook],
    Options[DocGenSaveSymbolPages]
    ];
AppSaveSymbolPages[
  appName_,
  dir:(_String|_File)?DirectoryQ|Automatic:Automatic,
  extension:True|False:False,
  ops:OptionsPattern[]]:=
  With[{app=AppFromFile[appName]},
    With[{pkgs=FileBaseName/@AppPackages[app]},
      Map[
        With[{nb=
          If[TrueQ@OptionValue[Monitor],
            With[{pkg=#},
              Function[
                Null,
                Monitor[#,
                  Internal`LoadingPanel[
                    "Creating symbol template notebook for ``"~TemplateApply~pkg
                    ]
                  ],
                HoldFirst
                ]
              ],
            Identity
            ]@
          CreateDocument[
            AppPackageSymbolNotebook[app,#,
              FilterRules[{ops},
                Options[AppPackageSymbolNotebook]
                ]
              ],
            Visible->False
            ]
          },
          Function[NotebookClose[nb]; #]@
            DocGenSaveSymbolPages[
              nb,
              Replace[dir,Automatic:>AppDirectory[app,"Symbols"]],
              extension,
              FilterRules[{ops},
                Options[DocGenSaveSymbolPages]
                ]
              ]
          ]&,
        pkgs
        ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*AppPackageSaveSymbolPages*)



Options[AppPackageSaveSymbolPages]=
  Join[
    Options[AppPackageSymbolNotebook],
    Options[DocGenSaveSymbolPages]
    ];
AppPackageSaveSymbolPages[
  appName_,
  pkg_,
  dir:(_String|_File)?DirectoryQ|Automatic:Automatic,
  extension:True|False:False,
  ops:OptionsPattern[]]:=
  With[{app=AppFromFile[appName]},
    With[{nb=
      If[TrueQ@OptionValue[Monitor],
        Function[
          Null,
          Monitor[#,
            Internal`LoadingPanel[
              "Creating symbol template notebook"
              ]
            ],
          HoldFirst
          ],
        Identity
        ]@
      CreateDocument[
        AppPackageSymbolNotebook[app,pkg,
          FilterRules[{ops},
            Options[AppPackageSymbolNotebook]
            ]
          ],
        Visible->False
        ]
      },
      Function[NotebookClose[nb]; #]@
        DocGenSaveSymbolPages[
          nb,
          Replace[dir,Automatic:>AppDirectory[app,"Symbols"]],
          extension,
          FilterRules[{ops},
            Options[DocGenSaveSymbolPages]
            ]
          ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*AppSaveGuide*)



Options[AppSaveGuide]=
  Join[
    Options[AppGuideNotebook],
    Options[DocGenSaveGuide]
    ];
AppSaveGuide[
  appName_, 
  dir:(_String|_File)?DirectoryQ|Automatic:Automatic,
  extension:True|False:False,
  ops : OptionsPattern[]] :=
  With[{app = AppFromFile[appName]},
    With[{nb =
      If[TrueQ@OptionValue[Monitor],
        Function[
          Null,
          Monitor[#,
            Internal`LoadingPanel[
              "Creating guide template notebook"
              ]
            ],
          HoldFirst
          ],
        Identity
        ]@
      CreateDocument[
        AppGuideNotebook[app, 
          FilterRules[{ops},
            Options[AppGuideNotebook]
            ]
          ], 
        Visible -> False]
      },
      Function[NotebookClose[nb]; #]@
        DocGenSaveGuide[
          nb,
          Replace[dir,Automatic:>AppDirectory[app, "Guides"]],
          extension,
          FilterRules[{ops},
            Options[DocGenSaveGuide]
            ]
          ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*AppPackageSaveGuide*)



Options[AppPackageSaveGuide]=
  Join[
    Options[AppPackageGuideNotebook],
    Options[DocGenSaveGuide]
    ];
AppPackageSaveGuide[
  appName_,
  pkg_,
  dir:(_String|_File)?DirectoryQ|Automatic:Automatic,
  extension:True|False:False,
  ops:OptionsPattern[]
  ]:=
  With[{
    app=AppFromFile[appName]
    },
    With[{nb=
      If[TrueQ@OptionValue[Monitor],
        Function[
          Null,
          Monitor[#,
            Internal`LoadingPanel[
              "Creating guide template notebook"
              ]
            ],
          HoldFirst
          ],
        Identity
        ]@
      Function[Global`bleb=NotebookGet[#];#]@
      CreateDocument[
        AppPackageGuideNotebook[app,pkg,
          FilterRules[{ops},
            Options[AppPackageGuideNotebook]
            ]
          ],
        Visible->False
        ]
      },
      Function[NotebookClose[nb];#]@
        DocGenSaveGuide[
          nb,
          Replace[dir,Automatic:>AppDirectory[app,"Guides"]],
          extension,
          FilterRules[{ops},
            Options[DocGenSaveGuide]
            ]
          ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*AppGenerateDocumentation*)



Options[AppGenerateDocumentation]=
  Join[
    Options[AppSaveSymbolPages],
    Options[AppSaveGuide]
    ];
AppGenerateDocumentation[
  app_,
  dir:(_String|_File)?DirectoryQ|Automatic:Automatic,
  extension:True|False:False,
  ops:OptionsPattern[]
  ]:=
  Module[{docs=dir},
    If[extension&&dir=!=Automatic,
      Quiet@
        CreateDirectory[
          FileNameJoin@{dir,"Documentation","English"},
          CreateIntermediateDirectories->True
          ];
      docs=FileNameJoin@{dir,"Documentation","English"}
      ];
    AppSaveSymbolPages[app,docs,extension,ops];
    AppPackageSaveGuide[app,#,docs,extension,ops]&/@
      FileBaseName/@AppPackages[app];
    AppSaveGuide[app,docs,extension,ops];
    docs
    ]


(* ::Subsubsection::Closed:: *)
(*AppPackageGenerateDocumentation*)



Options[AppPackageGenerateDocumentation]=
  Join[
    Options[AppPackageSaveSymbolPages],
    Options[AppPackageSaveGuide]
    ];
AppPackageGenerateDocumentation[
  app_,
  pkg_,
  dir:(_String|_File)?DirectoryQ|Automatic:Automatic,
  extension:True|False:False,
  ops:OptionsPattern[]
  ]:=
  Module[{docs=dir},
    If[extension&&dir=!=Automatic,
      Quiet@
        CreateDirectory[
          FileNameJoin@{dir,"Documentation","English"},
          CreateIntermediateDirectories->True
          ];
      docs=FileNameJoin@{dir,"Documentation","English"}
      ];
    AppPackageSaveSymbolPages[app,pkg,docs,extension,ops];
    AppPackageSaveGuide[app,pkg,docs,extension,ops];
    docs
    ]


(* ::Subsubsection::Closed:: *)
(*AppGenerateHTMLDocumentation*)



AppGenerateHTMLDocumentation[
  app_,
  dir:(_String|_File)?DirectoryQ|Automatic:Automatic,
  which:"ReferencePages"|"Guides"|"Tutorials"|All:All,
  pattern:_String:"*",
  ops:OptionsPattern[]
  ]:=
  With[{
    fils=
      Select[FileExistsQ@#&&StringMatchQ[FileBaseName[#],pattern]&]@
        FileNames[
          "*.nb",
          If[which===All,
            Replace[dir,{
              Automatic:>
                AppDirectory[app,"Documentation","English"],
              d_?DirectoryQ:>
                If[!FileNameSplit[d][[-2;;]]=={"Documentation","English"},
                  FileNameJoin@{d,"Documentation","English"},
                  d
                  ]
              }],
            Replace[dir,{
              Automatic:>
                AppDirectory[app,which],
              d_?DirectoryQ:>
                If[FileNameTake[d]=!=which,
                  FileNameJoin@{
                    If[!FileNameSplit[d][[-2;;]]=={"Documentation","English"},
                      FileNameJoin@{d,"Documentation","English"},
                      d
                      ],
                    which
                    },
                  d
                  ]
                }]
            ],
          \[Infinity]
          ]
    },
    DocGenGenerateHTMLDocumentation[
      Automatic,
      fils,
      ops
      ]
    ];


(* ::Subsubsection::Closed:: *)
(*AppPackageGenerateHTMLDocumentation*)



AppPackageGenerateHTMLDocumentation[
  app_,
  pkg_,
  which:"ReferencePages"|"Guides"|"Tutorials"|All:All,
  pattern:_String:"*",
  ops:OptionsPattern[]]:=
  With[{
    fils=
      Select[FileExistsQ@#&&StringMatchQ[FileBaseName[#],pattern]&]@
        Join[
          AppPath[app,"Symbols",#<>".nb"]&/@AppPackageFunctions[app,pkg],
          AppPath[app,#,pkg<>".nb"]&/@{"Guides","Tutorials"}
          ]
    },
    DocGenGenerateHTMLDocumentation[
      Automatic,
      fils,
      ops
      ]
    ];


End[];




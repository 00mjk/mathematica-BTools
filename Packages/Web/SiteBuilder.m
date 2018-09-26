(* ::Package:: *)



WebSites::usage="Lists websites";
WebSiteOptions::usage="Gets configuration options for a website";
WebSiteSetOptions::usage="Sets configuration options for a website";


WebSiteInitialize::usage="Makes a new website in a directory";
WebSiteNewContent::usage="Makes a new post notebook";
WebSiteNewTableOfContents::usage="Makes a new Table of Contents";


WebSiteThemes::usage="";
WebSiteFindTheme::usage="Finds the theme for a website";
WebSiteBuild::usage="Builds a website";
WebSiteDeploy::usage="Deploys a directory to the web";


WebSiteContent::usage="Finds content in a site";
WebSitePages::usage="Finds pages in a site";
WebSitePosts::usage="Finds posts in a site";


$WebSiteDirectory::usage=
  "The base directory for websites";
$WebSitePath::usage=
  "The path for finding websites";
$WebSiteThemePath::usage=
  "The path for website themes";
$WebSiteBuildErrors::usage=
  "A stack of errors encountered in the build process";


Begin["`Private`"];


(* ::Subsection:: *)
(*Config*)



(* ::Subsubsection::Closed:: *)
(*$WebSiteDirectory*)



$WebSiteDirectory=
  FileNameJoin@{
    $UserBaseDirectory,
    "ApplicationData",
    "WebSites"
    };


(* ::Subsubsection::Closed:: *)
(*$WebSitePath*)



$WebSitePath=
  {
    $WebSiteDirectory
    };


(* ::Subsubsection::Closed:: *)
(*$WebSiteThemePath*)



If[Length@OwnValues[$WebThemesURLBase]===0,
  $WebThemesURLBase:=
    $WebThemesURLBase=
      CloudObject["user:b3m2a1.paclets/PacletServer/Resources/SiteBuilder/Themes"][[1]]
  ];
$WebSiteTempThemeDir=
  FileNameJoin@{$TemporaryDirectory, "SiteBuilder_tmp", "Themes"};
$WebSiteThemePath=
  {
    PackageFilePath["Resources", "Themes"],
    FileNameJoin@{$WebSiteDirectory, "Themes"},
    $WebSiteTempThemeDir
    };


(* ::Subsubsection::Closed:: *)
(*WebSiteTemplateLibDirectory*)



$WebSiteTemplateLibDirectory=
  PackageFilePath["Resources","Themes","template_lib"];


(* ::Subsection:: *)
(*Site Config*)



(* ::Subsubsection::Closed:: *)
(*WebSiteFind*)



WebSites//Clear


WebSites[site_:"*"]:=
  Select[FileExistsQ@FileNameJoin@{#, "SiteConfig.wl"}&]@
    FileNames[site, $WebSitePath];
WebSiteFind[siteName_]:=
  SelectFirst[
    FileNames[siteName, $WebSitePath],
    FileExistsQ@FileNameJoin@{#, "SiteConfig.wl"}&,
    If[StringQ@siteName,
      FileNameJoin@{$WebSiteDirectory, siteName},
      $Failed
      ]
    ];


(* ::Subsubsection::Closed:: *)
(*Initialize*)



$WebSiteTemplate=
  PackageFilePath["Resources", "Templates", "SiteBuilder", "WebSite"];


WebSiteInitialize//Clear


WebSiteInitialize[
  dir_String?(
    FileNameDepth[#]>1&&DirectoryQ@DirectoryName[#]&
    ),
  template:_String?DirectoryQ|Automatic:Automatic,
  ops:OptionsPattern[]
  ]:=
  With[{temp=Replace[template, Automatic:>$WebSiteTemplate]},
    CopyDirectory[temp, dir];
    If[Length@Flatten@{ops}>0,
      Export[
        FileNameJoin@{dir,"SiteConfig.wl"},
        PrettyString@
          DeleteDuplicatesBy[First]@
            Flatten@
              {
                ops,
                Replace[
                  Get@FileNameJoin@{temp, "SiteConfig.wl"},
                  Except[_?OptionQ]:>{}
                  ]
                },
          "Text"
          ]
      ];
    dir
    ];


WebSiteInitialize[
  s_String?(
    FileNameDepth[#]==1||
      (Not@FileExistsQ[#]&&StringFreeQ[#,$PathnameSeparator])&),
  template:_String?DirectoryQ|Automatic:Automatic,
  ops:OptionsPattern[]
  ]:=
  (
    If[!DirectoryQ@$WebSiteDirectory,
      CreateDirectory[$WebSiteDirectory,CreateIntermediateDirectories->True]
      ];
    WebSiteInitialize[
      FileNameJoin@{$WebSiteDirectory, s}, 
      template,
      ops
      ]
    )


(* ::Subsubsection::Closed:: *)
(*Options*)



WebSiteOptions[dir_String?(DirectoryQ@*DirectoryName)]:=
  Replace[Quiet@Get[FileNameJoin@{dir, "SiteConfig.wl"}],
    Except[_?OptionQ]->
      {}
    ];
WebSiteOptions[dir_String?(DirectoryQ@*DirectoryName), vals_]:=
  FilterRules[
    WebSiteOptions[dir],
    vals
    ]


(* ::Subsubsection::Closed:: *)
(*SetOptions*)



WebSiteSetOptions[
  dir_String?(DirectoryQ@*DirectoryName),
  ops_?OptionQ
  ]:=
  Export[
    FileNameJoin@{dir,"SiteConfig.wl"},
    PrettyString@
      Merge[
        {
          WebSiteOptions[dir],
          ops
          },
        Last
        ],
    "Text"
    ];


(* ::Subsubsection::Closed:: *)
(*NewContent*)



webSiteNewContentAutoname[dir_, place_]:=
  ToUpperCase[StringTake[place, 1]]<>
    StringDrop[StringTrim[place, "s"], 1]<>
    " #"<>
    ToString@
    (
      1+Length@
        DeleteDuplicatesBy[FileBaseName]@
          FileNames["*.nb"|"*.md"|"*.html"|"*.xml",
            FileNameJoin@{dir, "content", place}]
      )


WebSiteNewContent[
  dir_String?DirectoryQ,
  place_String,
  name:_String|Automatic:Automatic,
  content:_List|_Cell|Automatic:Automatic,
  ops:OptionsPattern[]
  ]/;DirectoryQ@FileNameJoin@{dir,"content",place}:=
  With[
    {
      autoname=
        StringTrim[#, "."<>FileExtension[#]]<>".nb"&@
          Replace[name, Automatic:>webSiteNewContentAutoname[dir, place]]
      },
    If[!FileExistsQ@FileNameJoin@{dir,"content",place,autoname},
      SystemOpen@
      Export[FileNameJoin@{dir,"content",place,autoname},
        Notebook[Flatten@{
          Cell[
            BoxData@ToBoxes@
              Merge[{
                Switch[place,
                  "posts",
                    <|
                      "Title"->"< Post Title >",
                      "Slug"->Automatic,
                      "Date"->Now,
                      "Tags"->{},
                      "Authors"->{},
                      "Categories"->{}
                      |>,
                  "pages",
                    <|
                      "Title"->"< Page Title >",
                      "Slug"->Automatic
                      |>,
                  _,
                    <|
                      "Title"->"< Title >",
                      "Slug"->Automatic
                      |>
                  ],
                {ops}
                },
                Last
                ],
            "Metadata"
            ],
          Cell[
            "Check the style list for the entire set of supported styles",
            "Text"
            ],
          Cell[
            "Input style cells will be dropped",
            "Text"
            ],
          Replace[content,
            {
              Automatic:>
                Switch[place,
                  "posts",
                    Cell[
                      "This is a post, so article.html is the theme template for it.",
                      "Text"
                      ],
                  "pages",
                    Cell[
                      "This is a page, so page.html is the theme template for it.",
                      "Text"
                      ],
                  _,
                    Nothing
                  ]
              }
            ]
          },
          StyleDefinitions->
            FrontEnd`FileName[Evaluate@{$PackageName},
              "MarkdownNotebook.nb"
              ]
          ]
        ],
      $Failed
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*TableOfContents*)



WebSiteNewTableOfContents[dir_String?DirectoryQ]:=
  Module[
    {
      outdir,
      metas,
      data,
      cells,
      postCounter=1
      },
    outdir=
      FileNameJoin@{dir, "content", "posts"};
    metas=
      SortBy[
        AssociationMap[
          Association@
          Map[
            Rule@@StringTrim@StringSplit[#, ":",2]&,
            StringSplit[
              StringSplit[Import[#,"Text"], "\n\n",2][[1]],
              "\n"
              ]
            ]&,
          Select[
            FileNames["*.md",outdir,\[Infinity]],
            !StringMatchQ[FileBaseName[#], "toc"]&
            ]
          ],
        If[KeyMemberQ[#, "ID"],
          ToExpression[
            StringSplit[#ID, "."]
            ],
          {1000,1000,1000}
          ]&
        ];
    data=
      GroupBy[First->Last]/@
        GroupBy[#[[1,1]]&->(#[[1,2]]->#[[2]]&)]@
          KeyValueMap[
              If[KeyMemberQ[#2, "Path"], 
                Take[URLParse[#2["Path"], "Path"], UpTo[2]],
                {}
                ]->
              <|
                "Path"->
                  URLBuild[
                    Flatten@{
                      "..",
                      Most@FileNameSplit@StringTrim[#, outdir],
                      WebSiteBuildAttachExtension@#2["Slug"]
                      }
                    ],
                "Title"->
                  If[KeyMemberQ[#2, "Title"], 
                    #2["Title"],
                    "Post #"<>ToString[postCounter++]
                    ]
                |>&,
            metas
            ];
    cells=
      KeyValueMap[
        Cell[
          CellGroupData[Flatten@{
              Cell[#, "Section"],
              KeyValueMap[
                Cell[
                  CellGroupData[
                    Flatten@{
                      Cell[#,"Subsection"],
                      Map[
                        Cell[
                          TextData[
                            ButtonBox[#Title,
                               BaseStyle->"Hyperlink",
                              ButtonData->
                              {
                                FrontEnd`FileName[Evaluate@URLParse[#Path, "Path"]], 
                                None
                                }
                              ]
                            ],
                          "Item"
                          ]&,
                        #2
                        ]
                      }
                    ]
                  ]&,
                #2
                ]
              }
            ]
          ]&,
        data
        ];
  WebSiteNewContent[dir,
    "pages",
    "toc",
    cells,
    {
      "Title"->"Table of Contents",
      "Slug"->"toc"
      }
    ]
  ]


(* ::Subsubsection::Closed:: *)
(*FindTheme*)



WebSiteThemes[themePat_]:=
  Select[
    DirectoryQ@FileNameJoin@{#, "templates"}&
    ]@
    FileNames[themePat, $WebSiteThemePath]


validThemeURL[s_]:=
  With[{parse=URLParse[s]},
    MatchQ[parse["Scheme"], "http"|"https"]
    ];
WebSiteInstallTheme[
  themeURL_String?validThemeURL, 
  dir:_String?DirectoryQ|Automatic:Automatic
  ]:=
  With[{d=Replace[dir, Automatic:>$WebSiteTempThemeDir]},
    With[{arc=ExtractArchive[URLDownload[themeURL], d]},
      Replace[
        MinimalBy[DirectoryName/@arc, FileNameDepth],
        {
          {t_, ___}:>t,
          _->$Failed
          }
        ]
      ]
    ];


Options[WebSiteFindTheme]=
  {
    "DownloadTheme"->False
    };
WebSiteFindTheme[dir_String?DirectoryQ, theme_String,
  o:OptionsPattern[]
  ]:=
  SelectFirst[
    Join[
      {
        theme,
        FileNameJoin@{dir, "themes", theme},
        FileNameJoin@{dir, "theme"}
        },
      Map[
        FileNameJoin@{#, theme}&,
        $WebSiteThemePath
        ]
      ],
    DirectoryQ,
    If[OptionValue["DownloadTheme"]===True,
      Replace[
        WebSiteInstallTheme[
          URLBuild@{$WebThemesURLBase, theme<>".zip"}
          ],
        s_String:>
          WebSiteFindTheme[dir, theme, "DownloadTheme"->False]
        ],
      $Failed
      ]
    ];
WebSiteFindTheme[dir_String?DirectoryQ, op:OptionsPattern[]]:=
  Module[
    {
      ops=WebSiteOptions[dir],
      theme
      },
    Replace[
      Lookup[ops, "Theme"],
      {
        s_String:>
          WebSiteFindTheme[dir, s, op],
        _:>
          If[DirectoryQ@FileNameJoin@{dir, "theme"},
            FileNameJoin@{dir, "theme"},
            Replace[WebSiteFindTheme[dir, "minimal", op],
              $Failed:>
                SelectFirst[
                  FileNames["*", $WebSiteThemePath],
                  DirectoryQ@FileNameJoin@{#, "templates"}&
                  ]
              ]
            ]
        }
      ]
    ];


(* ::Subsubsection::Closed:: *)
(*Content*)



WebSiteContent[
  dir_String?DirectoryQ, 
  path:{___String}:{}, 
  contentPat:_?StringPattern`StringPatternQ
  ]:=
  DeleteDuplicatesBy[FileBaseName]@
    SortBy[FileExtension[#]=!="nb"&]@
      Select[Not@*DirectoryQ]@
        FileNames[contentPat, FileNameJoin@Flatten@{dir, "content", path}];


WebSitePages[dir_String?DirectoryQ, contentPat:_?StringPattern`StringPatternQ]:=
  WebSiteContent[dir, {"pages"}, contentPat]


WebSitePosts[dir_String?DirectoryQ, contentPat:_?StringPattern`StringPatternQ]:=
  WebSiteContent[dir, {"posts"}, contentPat]


(* ::Subsubsection::Closed:: *)
(*WebSiteOpenTheme*)



WebSiteOpenTheme[dir_, theme:_String|Automatic:Automatic]:=
  Replace[
    If[theme===Automatic,
      WebSiteFindTheme[dir],
      WebSiteFindTheme[dir, theme]
      ],
    d_String:>SystemOpen[d]
    ]


(* ::Subsection:: *)
(*ContentStack Manipulation*)



(* ::Subsubsection::Closed:: *)
(*WebSiteSetContentAttributes*)



WebSiteSetContentAttributes[
  fname_,
  props_
  ]:=
  (
    If[!AssociationQ@$WebSiteBuildContentStack[fname],
      $WebSiteBuildContentStack[fname]=<||>
      ];
    If[!AssociationQ@$WebSiteBuildContentStack[fname, "Attributes"],
      $WebSiteBuildContentStack[fname, "Attributes"]=<||>
      ];
    AssociateTo[
      $WebSiteBuildContentStack[fname, "Attributes"],
      props
      ]
    )


(* ::Subsubsection::Closed:: *)
(*WebSiteCollectContentURLs*)



(*WebSiteCollectContentURLs[]:=
	*)


(* ::Subsubsection::Closed:: *)
(*Cache*)



(* ::Subsubsubsection::Closed:: *)
(*Basic*)



WebSiteCachePath[dir_]:=
  FileNameJoin@{dir, "ContentCache.mx"};


WebSiteFindCache[dir_]:=
  Replace[WebSiteCachePath[dir],
    {
      f:Except[""|_?(Not@*FileExistsQ), _String]:>
        f,
      _->None
      }
    ]


WebSiteLoadCache[dir_]:=
  Replace[WebSiteFindCache[dir],
    {
      None-><||>,
      f_:>Replace[Quiet@Import[f], Except[_Association]-><||>]
      }
    ];


(* ::Subsubsubsection::Closed:: *)
(*Template*)



WebSiteTemplateCachePath[dir_]:=
  FileNameJoin@{dir, "TemplateCache.mx"};


WebSiteFindTemplateCache[dir_]:=
  Replace[WebSiteTemplateCachePath[dir],
    {
      f:Except[""|_?(Not@*FileExistsQ), _String]:>
        f,
      _->None
      }
    ]


WebSiteLoadTemplateCache[dir_]:=
  Replace[WebSiteFindTemplateCache[dir],
    {
      None-><||>,
      f_:>Replace[Quiet@Import[f], Except[_Association]-><||>]
      }
    ];


(* ::Subsubsubsection::Closed:: *)
(*webSitePrepContentName*)



webSitePrepContentName[content_, root_]:=
  If[StringQ@content,
    StringTrim[
      StringTrim[
        StringTrim[content, root], 
        $UserDocumentsDirectory
        ],
      $HomeDirectory
      ],
    content
    ]


(* ::Subsection:: *)
(*Site Building*)



(* ::Subsubsection::Closed:: *)
(*XMLTemplateApply*)



(* ::Subsubsubsection::Closed:: *)
(*xmlTemplateApplyInit*)



xmlTemplateApplyInit[root_, template_]:=
  (
    $WSBCachedBuildData["Context"]=$Context;
    $WSBCachedBuildData["ContextPath"]=$ContextPath;
    $WSBCachedBuildData["TemplatePath"]=$TemplatePath;
    $WSBCachedBuildData["Path"]=$Path;
    $TemplatePath=
      Join[
        Flatten@List@
          Replace[root, Automatic:>DirectoryName@template],
        $TemplatePath,
        {
          $WebSiteTemplateLibDirectory
          }
        ];
    $Path=
      Join[
        Flatten@List@
          Replace[root, Automatic:>DirectoryName@template],
        $Path,
        {
          $WebSiteTemplateLibDirectory
          }
        ];
    $Context="Templating`gen`";
    $ContextPath={"Templating`gen`", "Templating`lib`", "System`"};
    If[!TrueQ[$templateLibLoaded],
      Templating`lib`$$=<||>;
      Get[FileNameJoin@{"include", "lib", "loadTemplateLib.m"}];
      $templateLibLoaded=True
      ]
    );


(* ::Subsubsubsection::Closed:: *)
(*xmlTemplateApplyRestore*)



xmlTemplateApplyRestore[]:=
  (
    Quiet@Remove["Templating`gen`*"];
    System`Private`RestoreContextPath[];
    $Context=$WSBCachedBuildData["Context"];
    $TemplatePath=$WSBCachedBuildData["TemplatePath"];
    $Path=$WSBCachedBuildData["Path"];
    $ContextPath=$WSBCachedBuildData["ContextPath"];
    $WSBCachedBuildData//Clear
    )


(* ::Subsubsubsection::Closed:: *)
(*xmlTemplatePostProcessWhitespace*)



xmlTemplatePostProcessWhitespace[s_]:=
  StringReplace[s,
    {
      pre:(
        Shortest["<pre"~~___~~"</pre>"]
        ):>pre,
      Repeated[
        (Whitespace?(StringFreeQ["\n"])|"")~~"\n", 
        {2, \[Infinity]}
        ]->"\n"
      }
    ]


(* ::Subsubsubsection::Closed:: *)
(*xmlTemplateLoad*)



xmlTemplateLoad[template_]:=
  With[{tdat=$WebSiteTemplateCache[template]},
    If[MissingQ[tdat]||!DateObjectQ@$WebSiteLastBuild||
      FileDate[template, "Modification"]<=$WebSiteLastBuild,
      $WebSiteTemplateCache[template]=
        XMLTemplate[File[template]],
      tdat
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*WebSiteXMLTemplateApply*)



WebSiteXMLTemplateApply//Clear


WebSiteXMLTemplateApply[
  root:_String|{__String}|Automatic:Automatic,
  template:(_String|_File)?FileExistsQ,
  args:_?OptionQ:{}
  ]:=
  Replace[
    Internal`WithLocalSettings[
      xmlTemplateApplyInit[root, template],
      TemplateApply[
        xmlTemplateLoad[template],
        Templating`lib`$$=Association@args
        ],
      xmlTemplateApplyRestore[]
      ],
    {
      s_String:>
        xmlTemplatePostProcessWhitespace[s]
      }
    ]


(* ::Subsubsection::Closed:: *)
(*Utils*)



(* ::Subsubsubsection::Closed:: *)
(*WebSiteBuildSlug*)



WebSiteBuildSlug[fname_]:=
  With[{fe=FileExtension[fname]},
    StringReplace[
      Nest[StringTrim[StringTrim[#], "."<>fe]&, fname, 2], 
      {
        WhitespaceCharacter->"-",
        ent:"&#"~~NumberString~~";":>ent,
        "*"->"-ast-",
        "#"->"-num-",
        "."->"-dot-"
        }
      ]<>If[StringLength@fe>0, "."<>fe, ""]
    ]


(* ::Subsubsubsection::Closed:: *)
(*WebSiteBuildURL*)



WebSiteBuildURL[fname_]:=
  URLBuild@FileNameSplit@
    WebSiteBuildSlug@fname


(* ::Subsubsubsection::Closed:: *)
(*WebSiteBuildContentType*)



WebSiteBuildContentType[fname_,dir_]:=
  If[StringStartsQ[fname,dir],
    Replace[
      FileNameTake[
        If[FileNameTake[#,1]=="content",
          FileNameDrop[#,1],
          #
          ]&@
          FileNameDrop[fname,FileNameDepth@dir],
        1
        ],
      {
        "posts"->"post",
        "pages"->"page",
        _->"misc"
        }
      ],
    "misc"
    ]


(* ::Subsubsubsection::Closed:: *)
(*$WebSiteContentDirectoryTemplateMap*)



$WebSiteContentDirectoryTemplateMap=
  <|
    "post"->"article.html",
    "page"->"page.html",
    "misc"->"base.html"
    |>;


(* ::Subsubsubsection::Closed:: *)
(*WebSiteBuildGetTemplates*)



WebSiteBuildGetTemplates[content_,dir_]:=
  Replace[
    Fold[
      Lookup[#,#2,<||>]&,
      {$WebSiteBuildContentStack,"Attributes","Templates"}
      ],
    {
      s_String:>
        StringTrim@StringSplit[s,","],
      Except[_String|{__String}]:>
        Lookup[$WebSiteContentDirectoryTemplateMap,
          WebSiteBuildContentType[
            content,
            longDir
            ],
          "base.html"
          ]
      }
    ]


(* ::Subsubsubsection::Closed:: *)
(*WebSiteBuildFilePath*)



WebSiteBuildFilePath[fname_, dir_]:=
  If[StringStartsQ[fname, dir],
    If[FileNameTake[#,1]=="posts",
      FileNameDrop[#, 1],
      #
      ]&@
      If[FileNameTake[#, 1]=="content",
        FileNameDrop[#, 1],
        #
        ]&@
        FileNameDrop[fname, FileNameDepth@dir],
    FileNameTake[fname]
    ]


(* ::Subsubsubsection::Closed:: *)
(*$WebSiteBuildSafeExportXMLElements*)



$WebSiteBuildSafeExportXMLElements=
  Alternatives@@{
    "script",
    "style"
    };


(* ::Subsubsubsection::Closed:: *)
(*$WebSiteBuildSafeExportXMLMap*)



$WebSiteBuildSafeExportXMLMap=
  {
    "\""->"safeXMLExportProtectedCharacterQuot",
    "<"->"safeXMLExportProtectedCharacterLt",
    ">"->"safeXMLExportProtectedCharacterGt",
    "&"->"safeXMLExportProtectedCharacterAmp",
    "'"->"safeXMLExportProtectedCharacterApos"
    };


(* ::Subsubsubsection::Closed:: *)
(*WebSiteBuildSafeExportXML*)



WebSiteBuildSafeExportXML[xml_]:=
  StringReplace[
    ExportString[
      xml/.
        el:XMLElement[$WebSiteBuildSafeExportXMLElements, __]:>
        (el/.s_String:>StringReplace[s, $WebSiteBuildSafeExportXMLMap]),
      "XML"
      ],
    Reverse/@$WebSiteBuildSafeExportXMLMap
    ]


(* ::Subsubsubsection::Closed:: *)
(*WebSiteBuildAttachExtension*)



WebSiteBuildAttachExtension[s_]:=
  If[!MemberQ[{"html", "xml"}, ToLowerCase@FileExtension@s],
    StringTrim[s, "."<>FileExtension[s]]<>".html",
    s
    ]


(* ::Subsubsection::Closed:: *)
(*TemplateProcessFonts*)



(* ::Subsubsubsection::Closed:: *)
(*HTML Reps*)



(* ::Subsubsubsubsection::Closed:: *)
(*$XMLFontPatchDumbSpecialCharListLong*)



$XMLFontPatchDumbSpecialCharListLong=
  {
    "AliasDelimiter","AliasIndicator","Alpha","AltKey","And","AquariusSign",
    "AriesSign","AutoPlaceholder","Backslash","BeamedEighthNote","BeamedSixteenthNote","Beta",
    "BlackBishop","BlackKing","BlackKnight","BlackPawn","BlackQueen","BlackRook",
    "CancerSign","Cap","CapitalDifferentialD","CapitalDigamma","CapitalKoppa","CapitalSampi",
    "CapitalStigma","CapricornSign","Cent","CenterDot","CenterEllipsis","Checkmark",
    "Chi","CircleDot","CircleMinus","CirclePlus","CircleTimes","ClockwiseContourIntegral",
    "CommandKey","Conditioned","Conjugate","ConjugateTranspose","ConstantC","Continuation",
    "ContourIntegral","ControlKey","CounterClockwiseContourIntegral","Cross","Cup","CurlyCapitalUpsilon",
    "CurlyEpsilon","CurlyKappa","CurlyPhi","CurlyPi","CurlyRho","CurlyTheta",
    "DeleteKey","DifferenceDelta","DifferentialD","Digamma","DirectedEdge","DiscreteRatio",
    "DiscreteShift","DiscretionaryPageBreakAbove","DiscretionaryPageBreakBelow","Distributed","Divide","DotEqual",
    "DotlessJ","DottedSquare","DoubleDagger","DoubledGamma","DoubledPi","DoubleDownArrow",
    "DoubledPi","DoubleLeftArrow","DoubleLeftRightArrow","DoubleLeftTee","DoubleLongLeftArrow","DoubleLongLeftRightArrow",
    "DoubleLongRightArrow","DoubleRightArrow","DoubleStruckA","DoubleStruckB","DoubleStruckC","DoubleStruckA",
    "DoubleStruckB","DoubleStruckC","DoubleStruckCapitalA","DoubleStruckCapitalB","DoubleStruckCapitalC","DoubleStruckCapitalD",
    "DoubleStruckCapitalE","DoubleStruckCapitalF","DoubleStruckCapitalG","DoubleStruckCapitalH","DoubleStruckCapitalI","DoubleStruckCapitalJ",
    "DoubleStruckCapitalK","DoubleStruckCapitalL","DoubleStruckCapitalM","DoubleStruckCapitalN","DoubleStruckCapitalO","DoubleStruckCapitalP",
    "DoubleStruckCapitalQ","DoubleStruckCapitalR","DoubleStruckCapitalS","DoubleStruckCapitalT","DoubleStruckCapitalU","DoubleStruckCapitalV",
    "DoubleStruckCapitalW","DoubleStruckCapitalX","DoubleStruckCapitalY","DoubleStruckCapitalZ","DoubleStruckD","DoubleStruckE",
    "DoubleStruckEight","DoubleStruckF","DoubleStruckFive","DoubleStruckFour","DoubleStruckG","DoubleStruckH",
    "DoubleStruckI","DoubleStruckJ","DoubleStruckK","DoubleStruckL","DoubleStruckM","DoubleStruckN",
    "DoubleStruckNine","DoubleStruckO","DoubleStruckOne","DoubleStruckP","DoubleStruckQ","DoubleStruckR",
    "DoubleStruckS","DoubleStruckSeven","DoubleStruckSix","DoubleStruckT","DoubleStruckThree","DoubleStruckTwo",
    "DoubleStruckU","DoubleStruckV","DoubleStruckW","DoubleStruckX","DoubleStruckY","DoubleStruckZ",
    "DoubleStruckZero","DoubleUpArrow","DoubleUpDownArrow","DownArrowBar","DownArrow","DownBreve",
    "DownLeftRightVector","DownLeftTeeVector","DownLeftVector","DownLeftVectorBar","DownPointer","DownRightTeeVector",
    "DownRightVector","DownRightVectorBar","DownTeeArrow","Earth","EighthNote","Element",
    "Ellipsis","EmptyRectangle","EmptySet","EnterKey","EntityEnd","EntityStart",
    "Epsilon","Equal","Equilibrium","Equivalent","ErrorIndicator","EscapeKey",
    "Eta","Euro","ExponentialE","FilledSmallCircle","FinalSigma","FirstPage",
    "FormalA","FormalAlpha","FormalB","FormalBeta","FormalC","FormalCapitalA",
    "FormalCapitalAlpha","FormalCapitalB","FormalCapitalBeta","FormalCapitalC","FormalCapitalChi","FormalCapitalD",
    "FormalCapitalDelta","FormalCapitalDigamma","FormalCapitalE","FormalCapitalEpsilon","FormalCapitalEta","FormalCapitalF",
    "FormalCapitalG","FormalCapitalGamma","FormalCapitalH","FormalCapitalI","FormalCapitalIota","FormalCapitalJ",
    "FormalCapitalK","FormalCapitalKappa","FormalCapitalKoppa","FormalCapitalL","FormalCapitalLambda","FormalCapitalM",
    "FormalCapitalMu","FormalCapitalN","FormalCapitalNu","FormalCapitalO","FormalCapitalOmega","FormalCapitalOmicron",
    "FormalCapitalP","FormalCapitalPhi","FormalCapitalPi","FormalCapitalPsi","FormalCapitalQ","FormalCapitalR",
    "FormalCapitalRho","FormalCapitalS","FormalCapitalSampi","FormalCapitalSigma","FormalCapitalStigma","FormalCapitalT",
    "FormalCapitalTau","FormalCapitalTheta","FormalCapitalU","FormalCapitalUpsilon","FormalCapitalV","FormalCapitalW",
    "FormalCapitalX","FormalCapitalXi","FormalCapitalY","FormalCapitalZ","FormalCapitalZeta","FormalChi",
    "FormalCurlyCapitalUpsilon","FormalCurlyEpsilon","FormalCurlyKappa","FormalCurlyPhi","FormalCurlyPi","FormalCurlyRho",
    "FormalCurlyTheta","FormalD","FormalDelta","FormalDigamma","FormalE","FormalEpsilon",
    "FormalEta","FormalF","FormalFinalSigma","FormalG","FormalGamma","FormalH",
    "FormalI","FormalIota","FormalJ","FormalK","FormalKappa","FormalKoppa",
    "FormalL","FormalLambda","FormalM","FormalMu","FormalN","FormalNu",
    "FormalO","FormalOmega","FormalOmicron","FormalP","FormalPhi","FormalPi",
    "FormalPsi","FormalQ","FormalR","FormalRho","FormalS","FormalSampi",
    "FormalSigma","FormalStigma","FormalT","FormalTau","FormalTheta","FormalU",
    "FormalUpsilon","FormalV","FormalW","FormalX","FormalXi","FormalY",
    "FormalZ","FormalZeta","FreakedSmiley","Function","GeminiSign","GothicA",
    "GothicB","GothicC","GothicCapitalA","GothicCapitalB","GothicCapitalC","GothicCapitalD",
    "GothicCapitalE","GothicCapitalF","GothicCapitalG","GothicCapitalH","GothicCapitalI","GothicCapitalJ",
    "GothicCapitalK","GothicCapitalL","GothicCapitalM","GothicCapitalN","GothicCapitalO","GothicCapitalP",
    "GothicCapitalQ","GothicCapitalR","GothicCapitalS","GothicCapitalT","GothicCapitalU","GothicCapitalV",
    "GothicCapitalW","GothicCapitalX","GothicCapitalY","GothicCapitalZ","GothicD","GothicE",
    "GothicEight","GothicF","GothicFive","GothicFour","GothicG","GothicH",
    "GothicI","GothicJ","GothicK","GothicL","GothicM","GothicN",
    "GothicNine","GothicO","GothicOne","GothicP","GothicQ","GothicR",
    "GothicS","GothicSeven","GothicSix","GothicT","GothicThree","GothicTwo",
    "GothicU","GothicV","GothicW","GothicX","GothicY","GothicZ",
    "GothicZero","GrayCircle","GraySquare","Hacek","HermitianConjugate","ImaginaryI",
    "ImaginaryJ","Implies","IndentingNewLine","Iota","Kappa","KernelIcon",
    "Koppa","Lambda","LastPage","LeftArrow","LeftArrowRightArrow","LeftAssociation",
    "LeftBracketingBar","LeftDoubleBracket","LeftDoubleBracketingBar","LeftDownTeeVector","LeftDownVectorBar","LeftModified",
    "LeftRightArrow","LeftRightVector","LeftSkeleton","LeftTeeArrow","LeftTeeVector","LeftTriangleBar",
    "LeftTriangleEqual","LeftUpDownVector","LeftUpTeeVector","LeftUpVectorBar","LeftVector","LeftVectorBar",
    "LeoSign","LightBulb","Limit","LineSeparator","LibraSign","LongDash",
    "LongEqual","LongLeftArrow","LongLeftRightArrow","LongRightArrow","LowerLeftArrow","LowerRightArrow",
    "Mars","MathematicaIcon","MaxLimit","MinLimit","Mu","Natural",
    "Neptune","NestedGreaterGreater","NestedLessLess","NeutralSmiley","NotElement",
    "NotEqual","NotEqualTilde","NotGreaterGreater","NotGreaterSlantEqual","NotHumpDownHump","NotHumpEqual",
    "NotLeftTriangleBar","NotLessEqual","NotLessLess","NotLessSlantEqual","NotNestedGreaterGreater","NotNestedLessLess",
    "NotPrecedesEqual","NotPrecedesTilde","NotRightTriangleBar","NotSquareSubset","NotSquareSuperset","NotSucceedsEqual",
    "NotSucceedsTilde","NotVerticalBar","NumberSign","Omega","Omicron","OptionKey",
    "OverBracket","ParagraphSeparator","PermutationProduct","Phi","Pi","Piecewise",
    "PiscesSign","Placeholder","Proportional","Psi",
    "ReturnKey","ReverseElement","ReverseEquilibrium","ReverseUpEquilibrium","Rho","RightAngle",
    "RightArrow","RightArrowBar","RightArrowLeftArrow","RightAssociation","RightBracketingBar","RightCeiling",
    "RightDoubleBracket","RightDoubleBracketingBar","RightDownTeeVector","RightDownVector","RightDownVectorBar","RightModified",
    "RightSkeleton","RightTeeArrow","RightTeeVector","RightTriangleBar","RightUpDownVector","RightUpTeeVector",
    "RightUpVector","RightUpVectorBar","RightVector","RightVectorBar","RoundImplies","RoundSpaceIndicator",
    "Rule","RuleDelayed","SagittariusSign","Sampi","ScorpioSign","ScriptA",
    "ScriptB","ScriptC","ScriptCapitalA","ScriptCapitalB","ScriptCapitalC","ScriptCapitalD",
    "ScriptCapitalE","ScriptCapitalF","ScriptCapitalG","ScriptCapitalH","ScriptCapitalI","ScriptCapitalJ",
    "ScriptCapitalK","ScriptCapitalL","ScriptCapitalM","ScriptCapitalN","ScriptCapitalO","ScriptCapitalP",
    "ScriptCapitalQ","ScriptCapitalR","ScriptCapitalS","ScriptCapitalT","ScriptCapitalU","ScriptCapitalV",
    "ScriptCapitalW","ScriptCapitalX","ScriptCapitalY","ScriptCapitalZ","ScriptD","ScriptDotlessI",
    "ScriptDotlessJ","ScriptE","ScriptEight","ScriptF","ScriptFive","ScriptFour",
    "ScriptG","ScriptH","ScriptI","ScriptJ","ScriptK","ScriptL",
    "ScriptM","ScriptN","ScriptNine","ScriptO","ScriptOne","ScriptP",
    "ScriptQ","ScriptR","ScriptS","ScriptSeven","ScriptSix","ScriptT",
    "ScriptThree","ScriptTwo","ScriptU","ScriptV","ScriptW","ScriptX",
    "ScriptY","ScriptZ","ScriptZero","SelectionPlaceholder","ShortLeftArrow","ShortRightArrow",
    "Sigma","SpaceKey","SpanFromAbove","SpanFromBoth","SpanFromLeft","SphericalAngle",
    "Sqrt","Square","Sterling","Stigma","SuchThat","Sum",
    "SystemEnterKey","SystemsModelDelay","SZ","TabKey","Tau","TaurusSign",
    "TensorProduct","TensorWedge","Theta","Thorn","Transpose","TripleDot",
    "TwoWayRule","UnderBracket","UndirectedEdge","UnionPlus","UpArrowBar","UpArrowDownArrow",
    "UpEquilibrium","UpperLeftArrow","UpperRightArrow","UpPointer","Upsilon","UpTeeArrow",
    "Uranus","VerticalBar","VerticalSeparator","VirgoSign","WarningSign","WatchIcon",
    "WhiteBishop","WhiteKing","WhiteKnight","WhitePawn","WhiteQueen","WhiteRook",
    "Wolf","WolframLanguageLogo","WolframLanguageLogoCircle","Xi","Xnor","Yen",
    "Zeta"
    };
$XMLFontPatchDumbSpecialCharListConv=
  ToExpression@
    Map[
      "\"\\["<>#<>"]\""&,
      $XMLFontPatchDumbSpecialCharListLong
      ];


(* ::Subsubsubsubsection::Closed:: *)
(*$XMLFontPatchKeyboardElements*)



$XMLKBDPatchStyles=
  {"style"->"color: gray; font-size: 10px; border: solid 1px gray;"};


xmlFontPatchKBDEl[k_]:=
  XMLElement["span",
    Flatten@{$XMLKBDPatchStyles, $XMLFontPatchFlag},
    {XMLElement["kbd",{$XMLFontPatchFlag},{k}]}
    ];


$XMLFontPatchKeyboardElements=
  {
    "\\[AltKey]"|"\[AltKey]"->
      xmlFontPatchKBDEl@"ALT",
    "\\[CommandKey]"|"\[CommandKey]"->
      xmlFontPatchKBDEl["CMD"],
    "\\[ControlKey]"|"\[ControlKey]"->
      xmlFontPatchKBDEl@"CTRL",
    "\\[DeleteKey]"|"\[DeleteKey]"->
      xmlFontPatchKBDEl@"DEL",
    "\\[EnterKey]"|"\[EnterKey]"->
      xmlFontPatchKBDEl@"ENTER",
    "\\[EscapeKey]"|"\[EscapeKey]"->
      xmlFontPatchKBDEl@"ESC",
    "\\[OptionKey]"|"\[OptionKey]"->
      xmlFontPatchKBDEl@"OPTION",
    "\\[ReturnKey]"|"\[ReturnKey]"->
      xmlFontPatchKBDEl@"RET",
    "\\[ShiftKey]"|"\[ShiftKey]"->
      xmlFontPatchKBDEl@"SHIFT",
    "\\[SpaceKey]"|"\[SpaceKey]"->
      xmlFontPatchKBDEl@"SPACE",
    "\\[SystemEnterKey]"|"\[SystemEnterKey]"->
      xmlFontPatchKBDEl@"RET",
    "\\[TabKey]"|"\[TabKey]"->
      xmlFontPatchKBDEl@"TAB"
    };


(* ::Subsubsubsubsection::Closed:: *)
(*$XMLFontPatchManualUnicodeReassignments*)




$XMLFontPatchManualUnicodeReassignments=
  {
    "\\[KeyBar]"|"\[KeyBar]"->
      XMLElement["span", 
        Flatten@{$XMLFontPatchFlag, "style"->"font-weight: bold; font-size: 8px;"},
        {"\:2011"}
        ],
    "\\[RightPointer]"|"\[RightPointer]"->
      XMLElement["span", 
        Flatten@{$XMLFontPatchFlag, "style"->"font-weight: bold; font-size: 8px;"},
        {"\[FilledRightTriangle]"}
        ],
    "\\[LeftPointer]"|"\[LeftPointer]"->
      XMLElement["span", 
        Flatten@{$XMLFontPatchFlag, "style"->"font-weight: bold; font-size: 8px;"},
        {"\[FilledLeftTriangle]"}
        ]
    };


(* ::Subsubsubsubsection::Closed:: *)
(*$XMLFontPatchStringToXMLElementRules*)



$XMLFontPatchFlag=
  "-fake-attr-fonts-patched"->"true";


$XMLFontPatchDumbSpecialCharListLong=
  Alternatives@@$XMLFontPatchDumbSpecialCharListLong;
$XMLFontPatchDumbSpecialCharListConv=
  Alternatives@@$XMLFontPatchDumbSpecialCharListConv;


$XMLFontPatchStringToXMLElementRules=
  Flatten@
    {
      $XMLFontPatchKeyboardElements,
      $XMLFontPatchManualUnicodeReassignments,
      "\\["~~s:($XMLFontPatchDumbSpecialCharListLong)~~"]":>
        XMLElement["span",
          {
            "class"->"special-character "<>s,
            $XMLFontPatchFlag
            },
          {
            ToExpression["\"\\["<>s<>"]\""]
            }
          ],
      char:$XMLFontPatchDumbSpecialCharListConv:>
        XMLElement["span",
          {
            "class"->"special-character "<>CharacterName[char], 
            $XMLFontPatchFlag
            },
          {
            char
            }
          ]
      };


(* ::Subsubsection::Closed:: *)
(*TemplatePreProcess*)



$WebSiteTemplateAttachIDElements=
  {
    "pre", "h1", "h2", 
    "img", "p"
    }


(* ::Subsubsubsection::Closed:: *)
(*webSiteTemplatePreProcessAttachIDs*)



$WebSiteTemplateAttachIDElements=
  {"pre", "p", "blockquote", "img", "h1", "h2", "h3"}


webSiteTemplatePreProcessAttachIDs[xml_]:=
  Block[{$$id=1},
    ReplaceRepeated[
      xml,
      XMLElement[
        el:Alternatives@@$WebSiteTemplateAttachIDElements,
        c_?(Lookup[#,"id",None]===None&),
        e_
        ]:>
          XMLElement[el, Append[c, "id"->el<>ToString[$$id++]], e]
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*webSiteTemplatePreProcessPrettyPrint*)



webSiteTemplatePreProcessCodeHighlighting[tag_, lang_][xml_]:=
  With[
    {
      nullang=
        Switch[tag, 
          "prettyprint", "lang-none", 
          "highlight", "highlight-source-none",
          _, "language-none"
          ],
      langTag=
        Switch[tag, 
          "prettyprint", "lang-", 
          "highlight", "highlight-source-",
          _, "language-"
          ]
      },
    ReplaceRepeated[
      xml,
      XMLElement["pre",
        c_?(
            (StringFreeQ[Lookup[#,"class",""], tag|nullang])
            &),
        e_
        ]:>
        XMLElement["pre",
          Normal@
            ReplacePart[
              Association@c,
              "class"->
                StringTrim@
                  TemplateApply[
                    "`base` `tag` `lang`",
                    <|
                      "base"->Lookup[c, "class", ""],
                      "tag"->tag,
                      "lang"->
                        If[StringQ@lang&&StringFreeQ[Lookup[c, "class", ""], langTag],
                          langTag<>lang,
                          ""
                          ]
                      |>
                    ]
              ],
          e
          ]
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*webSiteTemplatePreProcessFonts*)



webSiteTemplatePreProcessFonts[xml_]:=
  ReplaceRepeated[
    ReplaceRepeated[
      xml,
      XMLElement[a_, b_?(FreeQ[$XMLFontPatchFlag]), d_]:>
        XMLElement[a,
          Append[b, $XMLFontPatchFlag],
          Replace[d,
            s_String:>
              Replace[StringExpression[expr___]:>expr]@
              StringReplace[
                s,
                $XMLFontPatchStringToXMLElementRules
                ],
            {1}
            ]
          ]
      ],
    XMLElement[a_, b_?(MemberQ[$XMLFontPatchFlag]), c_]:>
      XMLElement[a, Most[b], c]
    ]


(* ::Subsubsubsection::Closed:: *)
(*webSiteTemplatePreProcessInOut*)



$WebSiteTemplatePreProcessInOutToken=
  "(*Out:*)";
$WebSiteTemplatePreProcessInOutInTag=
  "mma-input";
$WebSiteTemplatePreProcessInOutOutTag=
  "mma-output";


(* ::Subsubsubsubsection::Closed:: *)
(*webSiteTemplatePreProcessSplitOutput*)



(* ::Text:: *)
(*
	webSiteTemplatePreProcessProcessSplitString
		does the actual dirty work of splitting the cells
*)



webSiteTemplatePreProcessProcessSplitString[splits_, pc_, cc_, head_, tail_]:=
  If[Length@DeleteCases[splits, ""]==0,
    Nothing,
    Sequence@@
      Flatten@{
        If[StringLength@splits[[1]]>0||Length@head>0,
          XMLElement["pre",
            DeleteDuplicatesBy[First]@
              Prepend[pc,
                "class"->
                  StringTrim[
                    Lookup[pc, "class", ""]<>" "<>
                      $WebSiteTemplatePreProcessInOutInTag
                    ]
                ],
            List@
              XMLElement["code",
                cc,
                Flatten@{head, splits[[1]]}
                ]
            ],
          Nothing
          ],
        If[Length@splits>2,
          Map[
            If[StringLength@#>0,
              XMLElement["pre",
                DeleteDuplicatesBy[First]@
                  Prepend[pc,
                    "class"->
                      StringTrim[
                        Lookup[pc, "class", ""]<>" "<>
                          $WebSiteTemplatePreProcessInOutOutTag
                        ]
                    ],
                List@
                  XMLElement["code",
                    cc,
                    {#}
                    ]
                ],
              Nothing
              ]&,
            Most@Rest@splits
            ],
          Nothing
          ],
        If[(Length@splits>1&&StringLength@Last@splits>0)||Length@Flatten@{tail}>0,
          XMLElement["pre",
            DeleteDuplicatesBy[First]@
              Prepend[pc,
                "class"->
                  StringTrim[
                    Lookup[pc, "class", ""]<>" "<>
                      $WebSiteTemplatePreProcessInOutOutTag
                    ]
                ],
            List@
              XMLElement["code",
                cc,
                Flatten@{
                  If[(Length@splits>1&&StringLength@Last@splits>0),
                    Last@splits,
                    Nothing
                    ], 
                  tail
                  }
                ]
            ],
          Nothing
          ]
        }
    ]


(* ::Text:: *)
(*
	webSiteTemplatePreProcessSplitOutput
		the more general function that delegates to the lower-level splitter
*)



webSiteTemplatePreProcessSplitOutput[pc_, cc_, head_, c_, tail_]:=
  Module[
    {
      splits=
        Block[{groupUpFlag=False},
          SplitBy[Flatten@{tail},
            Function[
              If[
                MatchQ[#,
                  _String?(StringContainsQ[$WebSiteTemplatePreProcessInOutToken])
                  ],
                groupUpFlag=Not@groupUpFlag
                ];
              groupUpFlag
              ]
            ]
          ],
      firstSplit=
        If[StringStartsQ[c, $WebSiteTemplatePreProcessInOutToken],
          Prepend[""],
          Identity
          ]@
        StringTrim@StringSplit[c, $WebSiteTemplatePreProcessInOutToken]
      },
    If[Length@DeleteCases[splits, {}]==0&&Length@DeleteCases[firstSplit, ""]==0,
      Nothing,
      Sequence@@
        Flatten@{
          If[Length@splits==0||StringQ@splits[[1, 1]],
            webSiteTemplatePreProcessProcessSplitString[firstSplit, 
              pc, cc, head, {}
              ],
            With[{sp=splits[[1]]},
              splits=Rest@splits;
              webSiteTemplatePreProcessProcessSplitString[firstSplit, 
                pc, cc, Join[head, sp]
                ]
              ]
            ],
          Map[
            webSiteTemplatePreProcessProcessSplitString[
              If[StringQ@#[[1]],
                (*If[StringStartsQ[#[[1]], $WebSiteTemplatePreProcessInOutToken],
									Prepend[""],
									Identity
									]@*)
                StringSplit[#[[1]], $WebSiteTemplatePreProcessInOutToken],
                {}
                ], 
              pc, 
              cc, 
              {},
              If[StringQ@#[[1]], Rest@#, #]
              ]&,
            splits
            ]
          }
      ]
    ]


(* ::Subsubsubsubsection::Closed:: *)
(*webSiteTemplatePreProcessInOut*)



webSiteTemplatePreProcessInOut[xml_]:=
  ReplaceRepeated[
    xml,
    {
      XMLElement["pre",
        pc_,
        {
          ___,
          XMLElement["code",
            cc_,
            {
              head:Shortest[___],
              c_String?(StringContainsQ[$WebSiteTemplatePreProcessInOutToken]),
              tail___
              }
            ],
          ___
          }
        ]:>
        webSiteTemplatePreProcessSplitOutput[pc, cc, {head}, c, {tail}],
      XMLElement["pre",
        pc_?(
          StringFreeQ[Lookup[#, "class", ""], 
            $WebSiteTemplatePreProcessInOutInTag|
            $WebSiteTemplatePreProcessInOutOutTag
            ]&
          ),
        c:{
          ___,
          XMLElement["code",
            _,
            {
              _String?(StringFreeQ[$WebSiteTemplatePreProcessInOutToken])
              }
            ],
          ___
          }
        ]:>
        XMLElement["pre",
          DeleteDuplicatesBy[First]@
            Prepend[pc,
              "class"->
                StringTrim[
                  Lookup[pc, "class", ""]<>" "<>
                    $WebSiteTemplatePreProcessInOutInTag
                  ]
              ],
          c
          ]
      }
    ]


(* ::Subsubsubsection::Closed:: *)
(*WebSiteTemplatePreProcess*)



WebSiteTemplatePreProcess[fileContent_,args_]:=
  Module[
    {
      ids=
        Lookup[args, "AttachIDs"],
      idtags,
      lang=
        Lookup[args, "CodeLanguage"],
      highlight=
        Lookup[args, "CodeHighlighting"],
      prettyprint=
        Lookup[args, "PrettyPrint"],
      patchfonts=
        Lookup[args, "PatchFonts"],
      splitout=
        Lookup[args, "SplitInOut"],
      splittags,
      srcbase=
        Replace[Lookup[args, "SiteURL"], Except[_String]:>""]
      },
    If[StringQ@ids,
      idtags=ids;
      ids=True,
      idtags=$WebSiteTemplateAttachIDElements
      ];
    If[OptionQ@splitout,
      splittags=
        MapThread[
          If[StringQ@#, #, #2]&,
          {
            Lookup[splitout, 
              {
                "Token",
                "OutTag",
                "InTag"
                }
              ],
            {
              $WebSiteTemplatePreProcessInOutToken,
              $WebSiteTemplatePreProcessInOutInTag,
              $WebSiteTemplatePreProcessInOutOutTag
              }
            }
          ],
      splittags=
        {
          $WebSiteTemplatePreProcessInOutToken,
          $WebSiteTemplatePreProcessInOutInTag,
          $WebSiteTemplatePreProcessInOutOutTag
          }
      ];
    If[StringQ[srcbase],
      ReplaceAll[
        #,
        ("src"->f_):>
          ("src"->StringReplace[f, "{filename}"->srcbase])
        ]&,
      Identity
      ]@
    If[TrueQ@ids,
      Block[
        {
          $WebSiteTemplateAttachIDElements=idtags
          },
        webSiteTemplatePreProcessAttachIDs
        ],
      Identity
      ]@
    If[
      TrueQ[prettyprint]||
        (StringQ[lang]&&!TrueQ[highlight]&&!StringQ[highlight]&&prettyprint=!=False),
      webSiteTemplatePreProcessCodeHighlighting[
        "prettyprint",
        If[StringQ@lang, lang, None]
        ],
      Identity
      ]@
    If[TrueQ[highlight],
      webSiteTemplatePreProcessCodeHighlighting[
        "highlight",
        If[StringQ@lang, lang, None]
        ],
      Identity
      ]@
    If[StringQ[highlight],
      webSiteTemplatePreProcessCodeHighlighting[
        highlight,
        If[StringQ@lang, lang, None]
        ],
      Identity
      ]@
    If[TrueQ[patchfonts],
      webSiteTemplatePreProcessFonts,
      Identity
      ]@
    If[TrueQ[splitout],
      Block[
        {
          $WebSiteTemplatePreProcessInOutToken=splittags[[1]],
          $WebSiteTemplatePreProcessInOutInTag=splittags[[2]],
          $WebSiteTemplatePreProcessInOutOutTag=splittags[[3]]
          },
        webSiteTemplatePreProcessInOut[#]
        ]&,
      Identity
      ]@
      FirstCase[
        fileContent,
        XMLElement["body",_,b_]:>
          b,
        fileContent,
        \[Infinity]
        ]
    ]


(* ::Subsubsection::Closed:: *)
(*TemplateGatherArgs*)



(* ::Subsubsubsection::Closed:: *)
(*$WebSiteSummaryBaseUnits*)



$WebSiteSummaryBaseUnits=
  {
    "Characters","Words","Characters",
    "Sentences","Paragraphs","Lines"
    };


(* ::Subsubsubsection::Closed:: *)
(*$WebSiteSummaryIndependentUnits*)



$WebSiteSummaryIndependentUnits:=
  $WebSiteSummaryIndependentUnits=
    Quantity/@$WebSiteSummaryBaseUnits//QuantityUnit;


(* ::Subsubsubsection::Closed:: *)
(*$WebSiteSummaryUnits*)



$WebSiteSummaryUnits:=
  $WebSiteSummaryUnits=
    Alternatives@@
      Join[$WebSiteSummaryBaseUnits,$WebSiteSummaryIndependentUnits]


(* ::Subsubsubsection::Closed:: *)
(*webSiteTemplateGatherSummary*)



webSiteTemplateGatherSummary[len_, content_]:=
  Module[
    {
      sl,
      cont
      },
    sl=
      Replace[
        len,
        {
          i_Integer?Positive:>
            {i, "Characters"},
          _[i_Integer?Positive, u:Alternatives@@$WebSiteSummaryBaseUnits]:>
            {i, u},
          _:>
            {3,"Sentences"}
          }
        ];
    cont=ImportString[content, "HTML"];
    Replace[sl,
      {
        {
          i_,
          "Characters"|IndependentUnit["characters"]
          }:>
          Function[
            If[
              StringLength[#]>i,
              StringTake[#,i-3]<>"...",
              #
              ]
            ]@
            StringReplace[cont,Whitespace->" "],
        {
          i_,
          "Lines"|IndependentUnit["lines"|"lines of code"]
          }:>
          StringRiffle@
            Take[
              StringSplit[cont,"\n"],
              UpTo[i]
              ],
        {
          i_,
          IndependentUnit[t_]|t_String
          }:>
          StringRiffle[
            TextCases[cont,
              ToUpperCase[StringTake[#,1]]<>
                StringDrop[#,1]&@t,
              i],
            " "
            ]
        }
    ]
  ]


(* ::Subsubsubsection::Closed:: *)
(*WebSiteTemplateGatherArgs*)



WebSiteTemplateGatherArgs[fileContent_, args_]:=
  Module[
    {
      url,
      slug,
      fp,
      title,
      content,
      summary,
      date,
      modified,
      siteURL,
      siteName
      },
    url=Lookup[args, "URL"];
    slug=Lookup[args, "Slug"];
    fp=Lookup[args, "FilePath"];
    content=
      Replace[fileContent,
        {
          l:{__XMLElement}:>
            StringRiffle[
              WebSiteBuildSafeExportXML/@l,
              "\n"
              ],
          x_XMLElement:>
            WebSiteBuildSafeExportXML[x],
          None->
            "<html><body>No content...</body><html>",
          e:Except[_String]:>
            (
              WebSiteBuildLogError[fp, "BadContent", e];
              PackageThrowMessage[
                "SiteBuilder",
                Evaluate[WebSiteBuild::nocnt],
                Short[e]
                ]
              )
          }
        ];
    title=
      Replace[
        FirstCase[
          If[StringQ[fileContent],
            ImportString[fileContent, {"HTML", "XMLObject"}],
            fileContent
            ],
          t:XMLElement["title", _, _]:>
            System`Convert`XMLDump`getSymbolicXMLPlaintext@
              XMLElement["body",{}, t],
          None,
          \[Infinity]
          ],
        {
          Except[_String]->
            None,
          s_String:>
            s
          }
        ];
    summary=
      Replace[
        Lookup[args, "Summary"],
        Except[_String?(StringLength[#]>0&)]:>
          webSiteTemplateGatherSummary[
            Lookup[args, "SummaryLength"],
            content
            ]
        ];
    date=
      Replace[
        Lookup[args,"Date",Now],
        s_String:>Quiet@Check[DateObject[s], s]
        ];
    modified=
      Replace[
        Lookup[args,"Modified",Now],
        s_String:>Quiet@Check[DateObject[s], s]
        ];
    siteURL=
      Replace[
        Lookup[args, "SiteURL", Automatic],
        Automatic:>
          With[{
            bit=
              Length@
                Replace[
                  Lookup[args,"URL",
                    FileNameSplit@
                      Lookup[args, "FilePath", "??"]
                    ],
                  s_String:>
                    URLParse[s,"Path"]
                  ]
            },
            Replace[
              bit,
              {
                1->".",
                n_:>
                  URLBuild@ConstantArray["..",n-1]
                }
              ]
            ]
        ];
    siteName=
      Replace[
        Lookup[args,"SiteName",Automatic],
        {
          s_String:>
            URLParse[s,"Path"][[-1]],
          Except[_String]:>
            Replace[
              Lookup[args, "SiteURL"],
              {
                s_String:>
                  URLParse[s,"Path"][[-1]],
                Except[_String]:>
                  Replace[Lookup[args, "SiteDirectory"],
                    Except[_String]:>
                      Replace[$WolframID,{
                        s_String:>
                          StringSplit[s,"@"][[1]],
                        _->$UserName
                        }]
                    ]
                }
              ]
          }
        ];
    Merge[
      {
        args,
        If[StringQ@title, "Title"->title, Nothing],
        "Summary"->summary,
        "Date"->date,
        "Modified"->modified,
        "SiteName"->siteName,
        "SiteURL"->siteURL,
        Which[
          StringQ@url,
            "URL"->url,
          StringQ@slug,
            "URL"->
              If[StringQ[fp],
                URLBuild@
                  Append[Most@FileNameSplit[fp], WebSiteBuildAttachExtension@slug],
                WebSiteBuildAttachExtension@slug
                ],
          True,  
            Nothing
          ],
        "Content"->
          content
        },
      Last
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*TemplateApply*)



WebSiteTemplateApply//ClearAll


(* ::Text:: *)
(*
	Iteratively apply templates to the provided content, unwrapping from or reexporting to XML as necessary. Generally only one template will be used and imports will be handled within the template.
*)



WebSiteBuild::nocnt=
  "Can't export content `` to string";
WebSiteTemplateApply[
  root:_String?DirectoryQ|{__String?DirectoryQ},
  content:_String|_File|None,
  templates:{__String}|_String,
  info:_Association:<||>
  ]:=
  If[AssociationQ@$WebSiteBuildContentStack,
    Module[
      {
        cname,
        fils,
        args
        },
        cname=webSitePrepContentName[content, root];
        fils=
          Replace[
            With[
              {
                dp=
                  Map[
                    FileNameJoin@*FileNameSplit,
                    Append[root, 
                      FileNameJoin@{$WebSiteTemplateLibDirectory, "templates"}
                      ]
                    ]
                },
              SortBy[
                FileNames[#, dp],
                Position[dp, FileNameJoin@FileNameSplit@DirectoryName@#]&
                ]
              ],
            {
              {f_, ___}:>f
              }
            ]&/@Flatten@List@templates//Flatten;
      args=
        If[MemberQ[Lookup[#, "Templates", {}], "article.html"],
          Merge[{
            #,
            "Categories"->{"misc"}
            },
            Replace[{
              {l_List,l2_List}:>
                DeleteDuplicates@Flatten@{l,l2},
              {e_}:>e
              }]
            ],
          #
          ]&@
        Merge[(* Collect the arguments to pass to the template *)
          {
            $WebSiteBuildAggStack,
            info,
            (* Include extracted attributes *)
            Lookup[
              Lookup[
                $WebSiteBuildContentStack, 
                cname,
                <||>
                ],
              "Attributes",
              {}
              ]
            },
          Last
          ];
      (* Allows for custom slugs *)
      Lookup[
        Fold[
          Lookup[#, #2, <||>]&,
          $WebSiteBuildContentStack,
          {cname, "Attributes"}
          ],
        "Slug",
        Automatic
        ]->
        Fold[
          WebSiteXMLTemplateApply[
            root,
            #2,
            WebSiteTemplateGatherArgs[
              #,
              args
              ]
            ]&,
          If[cname=!=None,
            $WebSiteBuildContentStack[cname, "Content"],
            None
            ],
          fils
          ]
        ],
    PackageThrowMessage[
      Automatic,
      Evaluate[WebSiteBuild::nost]
      ];
    $Failed
    ]


(* ::Subsubsection::Closed:: *)
(*TemplateExport*)



WebSiteTemplateExport[
  failinput_,
  fout_,
  root_,
  content_,
  templates_,
  config_
  ]:=  
  Replace[
    WebSiteTemplateApply[
      root,
      content,
      templates,
      config
      ],
    {
      (f_->html_String):>
        With[
          {
            fil=
              Replace[f,
                {
                  Automatic:>
                    WebSiteBuildAttachExtension@fout,
                  s_String:>
                    FileNameJoin@
                      Append[
                        Most@FileNameSplit[fout],
                        WebSiteBuildAttachExtension@s
                        ]
                  }]
              },
          If[
            !FileExistsQ[fil]||(* to preserve the modification date *)
              (html=!=System`Convert`TextDump`PlaintextImport[fil][[2]]),
            Quiet@Close[fil];
            If[!DirectoryQ@DirectoryName[fil],
              CreateDirectory[DirectoryName[fil], 
                CreateIntermediateDirectories->True
                ]
              ];
            Export[fil, html, "Text"]
            ]
          ],
      e_:>
        (
          WebSiteBuildLogError[failinput, "GenerationFailed", e]; 
          Message[WebSiteBuild::genfl, failinput];$Failed
          )
      }
    ];


(* ::Subsubsection::Closed:: *)
(*TemplateExportPaginated*)



Options[WebSiteTemplateExportPaginated]=
  {
    "PageSize"->0,
    Monitor->True
    };
WebSiteTemplateExportPaginated[
  failInput_,
  baseName_,
  dir_, outDir_,
  root_,
  content_,
  templates_,
  config_,
  articles_,
  ops:OptionsPattern[]
  ]:=
  Block[
    {
      pageSize=
        OptionValue["PageSize"],
      page=""
      },
      If[TrueQ@OptionValue[Monitor], Monitor, #&][
        If[IntegerQ[pageSize]&&pageSize>0&&
          MemberQ[{"html", ""}, FileExtension[baseName]],
          Table[
            WebSiteTemplateExport[
              failInput<>If[i>1, ", page "<>ToString[i], ""],
              FileNameJoin@{
                dir, 
                StringTrim[baseName, ".html"]<>
                  If[i>1, ToString[i], ""]<>".html"
                },
              root,
              None,
              templates,
              Merge[
                {
                  config,
                  "URL"->
                    Set[
                      page,
                      WebSiteBuildURL@
                        FileNameDrop[
                          FileNameJoin@{
                            dir, 
                            baseName<>If[i>1, ToString[i], ""]<>".html"
                            },
                          FileNameDepth[outDir]
                          ]
                      ],
                  "IndexListing"->
                    Take[
                      articles, 
                      {1+pageSize*(i-1), UpTo[pageSize*i]}
                      ],
                  "PageNumber"->i,
                  "PageNumberTotal"->
                    Ceiling[Length[articles]/pageSize],
                  "PageSize"->pageSize,
                  "PreviousPageURL"->
                    If[i>1,
                      WebSiteBuildURL@
                        FileNameDrop[
                          FileNameJoin@{
                            dir, 
                            baseName<>If[i-1>1, ToString[i-1], ""]<>".html"
                            },
                          FileNameDepth[outDir]
                          ],
                      None
                      ],
                  "NextPageURL"->
                    If[i<Ceiling[Length[articles]/pageSize],
                      WebSiteBuildURL@
                        FileNameDrop[
                          FileNameJoin@{
                            dir, 
                            baseName<>ToString[i+1]<>".html"
                            },
                          FileNameDepth[outDir]
                          ],
                      None
                      ]
                  },
                Last
                ]
              ],
            {i, Ceiling[Length[articles]/pageSize]}
            ],
          WebSiteTemplateExport[
            failInput,
            FileNameJoin@{
                dir, 
                WebSiteBuildAttachExtension@baseName
                },
            root,
            None,
            templates,
            Merge[
              {
                config,
                "IndexListing"->
                  articles,
                "URL"->
                  Set[
                    page,
                    WebSiteBuildURL@
                      FileNameDrop[
                        FileNameJoin@{
                          dir, 
                          WebSiteBuildAttachExtension@baseName
                          },
                        FileNameDepth[outDir]
                        ]
                    ]
                },
              Last
              ]
            ]
          ];,
        Internal`LoadingPanel@
          TemplateApply["Generating ``", page]
        ];
    ];


(* ::Subsubsection::Closed:: *)
(*ImportMeta*)



WebSiteImportMeta[xml:(XMLObject[___][___]|XMLElement["html",___])]:=
  WebSiteImportMeta/@
    Cases[xml,
      XMLElement["meta",__],
      \[Infinity]
      ];
WebSiteImportMeta[
  XMLElement["meta",info_,_]
  ]:=
  Replace[
    Lookup[
      info,
      {"name", "content"},
      Nothing
      ],{
    {n_,c_}:>
      n->
        If[MemberQ[$DefaultWebSiteAggregationTypes, n]||
          StringContainsQ[c, 
            Repeated[
              __~~Except[WhitespaceCharacter|","]~~","~~
                Except[WhitespaceCharacter|","],
              {2}
              ]
            ]||
          StringMatchQ[c, 
            WordCharacter..~~Except[WhitespaceCharacter|","]~~","~~
              Except[WhitespaceCharacter|","]~~WordCharacter..
            ],
          StringTrim@StringSplit[c,","],
          c
          ],
    _->Nothing
    }];


(* ::Subsubsection::Closed:: *)
(*ContentStackPrep*)



WebSiteContentStackPrep[]:=
  If[AssociationQ@$WebSiteBuildContentStack,
    $WebSiteBuildContentDataStack=
      Association@
        Map[
          #["Attributes", "URL"]->#&,
          Values@$WebSiteBuildContentStack
          ];
    $WebSiteBuildAggStack=
      <|
        (* A function for getting object attributes by file name *)
        "ContentStack"->
          Function[
            Lookup[$WebSiteBuildContentStack, #,
              Lookup[$WebSiteBuildContentDataStack, #, None]
              ]
            ],
        (* This is filled in later by the aggregation generator (if aggregations turned on) *)
        "AggregationStack"->
          Function@PackageThrowMessage["SiteBuilder", "Aggregations not turned on"],
        (* A function for getting object attributes by file name *)
        "ContentData"->
          Function[
            Lookup[
              Lookup[
                $WebSiteBuildContentDataStack, #,
                Lookup[$WebSiteBuildContentStack, #, <||>]
                ],
              "Attributes",
              <||>
              ]
            ],
        (* A function for choosing objects by the template used *)
        "SelectObjects"->
          Function[
            With[{type=StringTrim[ToLowerCase[#], ".html"]<>".html"},
              Select[
                Values@
                  $WebSiteBuildContentStack[[All, "Attributes"]],
                MemberQ[#["Templates"], type]&
                ]
              ]
            ],
        (* A function for getting objects sorted by some function *)
        "SortedObjectsBy"->
          Function[
            With[{
              order=#,
              pageType=If[Length@{##}>1, {##}[[2]], "article"]
              },
              SortBy[order]@
                $WebSiteBuildAggStack["SelectObjects"][pageType]
              ]
            ],
        (* A function for getting the next object by some function *)
        "NextObjectBy"->
          Function[
            With[{
              self=#,
              order=#2,
              pageType=If[Length@{##}>2, {##}[[3]], "article"]
              },
              With[
                {
                  sorted=
                    SortBy[order]@
                    $WebSiteBuildAggStack["SelectObjects"][pageType]
                  },
                With[{pos=1+FirstPosition[sorted, self][[1]]},
                  If[pos<=Length@sorted,
                    sorted[[pos]],
                    None
                    ]
                  ]
                ]
              ]
            ],
        (* A function for getting the previous object by some function *)
        "PreviousObjectBy"->
          Function[
            With[{
              self=#,
              order=#2,
              pageType=If[Length@{##}>2, {##}[[3]], "article"]
              },
              With[
                {
                  sorted=
                    SortBy[order]@
                    $WebSiteBuildAggStack["SelectObjects"][
                      pageType
                      ]
                  },
                With[{pos=FirstPosition[sorted, self][[1]]-1},
                  If[pos>0,
                    sorted[[pos]],
                    None
                    ]
                  ]
                ]
              ]
            ],
        (* The pages *)
        "Pages":>
          $WebSiteBuildAggStack["SelectObjects"]["page.html"],
        (* The articles *)
        "Articles":>
          $WebSiteBuildAggStack["SelectObjects"]["article.html"],
        (* The archives *)
        "Archives":>
          Reverse@
            GatherBy[
              Values@
                $WebSiteBuildContentStack[[All,"Attributes"]],
              #["Date"]&
              ]
        |>;
    ]


(* ::Subsubsection::Closed:: *)
(*ExtractPageData*)



(* ::Subsubsubsection::Closed:: *)
(*WebSiteExtractFileData*)



WebSiteBuild::nost="$WebSiteBuildContentStack not initialzed";
WebSiteExtractFileData[root_, content_, config_]:=
  If[AssociationQ@$WebSiteBuildContentStack,
    Module[
      {
        fileContent,
        args,
        cname
        },
      fileContent=
        Replace[content,{
          (_File|_String)?FileExistsQ:>
            Switch[FileExtension[content],
              "md",
                MarkdownToXML[Import[content,"Text"]],
              "html"|"xml",
                Import[content, {"HTML","XMLObject"}]
              ]
          }];
      cname=webSitePrepContentName[content, root];
      args=
        Merge[
          {
            config,
            Replace[fileContent,
              {
                (XMLObject[___][___]|XMLElement["html",___]):>
                  KeyDrop[WebSiteImportMeta[fileContent],
                    "URL"
                    ],
                _->{}
                }
              ],
            "SourceFile"->content
            },
          Last
          ];
      If[cname=!=None,
        $WebSiteBuildContentStack[cname]=
          <|
            "Attributes"->
                WebSiteTemplateGatherArgs[fileContent, args]
            |>;
        $WebSiteBuildContentStack[cname, "Content"]=
          WebSiteTemplatePreProcess[fileContent,
            $WebSiteBuildContentStack[cname, "Attributes"]
            ];
        ];
      ],
    Message[WebSiteBuild::nost];
    $Failed
    ];


(* ::Subsubsubsection::Closed:: *)
(*WebSiteExtractPageData*)



Options[WebSiteExtractPageData]=
  {
    Monitor->True,
    "LastBuild"->None
    };
WebSiteExtractPageData[rootDir_, files_,config_, ops:OptionsPattern[]]:=
  Block[
    {
      extractfile="",
      lb=OptionValue["LastBuild"]
      },
    If[TrueQ@OptionValue[Monitor], Monitor, #&][
      Module[
        {
          fname=
            Replace[#,
              f:Except[_String|_File]:>
                ExpandFileName@First[f]
              ],
          templates=
            Flatten@List@
            Replace[#,{
              r:Except[_String|_File]:>
                Last[r],
              _->"base.html"
              }],
          cname
          },
        extractfile=fname;
        cname=webSitePrepContentName[fname, rootDir];
        If[KeyFreeQ[$WebSiteBuildContentStack, cname]&&
            (!DateObjectQ[lb]||lb<=FileDate[fname, "Modification"]),
          WebSiteExtractFileData[
            rootDir,
            fname,
            Merge[
              {
                config,
                "Templates"->
                  templates,
                "FilePath"->
                  WebSiteBuildFilePath[fname, rootDir]
                },
              Last
              ]
            ]
          ]
        ]&/@files,
      Internal`LoadingPanel@
        TemplateApply[
          "Extracting data from ``",
          extractfile
          ]
      ]
    ];


(* ::Subsubsection::Closed:: *)
(*CopyTheme*)



(* ::Subsubsubsection::Closed:: *)
(*webSiteCopyTheme*)



webSiteCopyTheme[outDir_, thm_, mon_]:=
  With[{fils=Select[Not@*DirectoryQ]@FileNames["*",thm,\[Infinity]]},
    Block[
      {
        copyfile,
        newfile
        },
      If[TrueQ@mon, Monitor, #&][
        With[
          {
            newf=
              FileNameJoin@{outDir, "theme",
                FileNameDrop[#, FileNameDepth[thm]]
                }
            },
          If[!(FileExistsQ[newf]&&FileHash[#]==FileHash[newf]),
            copyfile=#;
            newfile=newf;
            If[!DirectoryQ@DirectoryName@newf,
              CreateDirectory[DirectoryName@newf,
                CreateIntermediateDirectories->True
                ]
              ];
            CopyFile[#,newf,OverwriteTarget->True]
            ];
          copyfile=.;
          newfile=.;
          ]&/@fils,
        Internal`LoadingPanel@
          If[AllTrue[{copyfile,newfile},StringQ],
            TemplateApply["Copying `` to ``",
              {
                copyfile,
                newfile
                }
              ],
            TemplateApply[
              "Copying theme ``",
              thm
              ]
            ]
        ]
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*WebSiteCopyTheme*)



WebSiteCopyTheme//Clear


Options[WebSiteCopyTheme]=
  {
    Monitor->True
    };
WebSiteCopyTheme[dir_,outDir_, theme_,
  ops:OptionsPattern[]
  ]:=
  With[
    {
      thm=
        FileNameJoin@{
          WebSiteFindTheme[dir, theme, "DownloadTheme"->True],
          "static"
          },
      common=
        FileNameJoin@{
          $WebSiteTemplateLibDirectory,
          "static"
          }
      },
    Quiet@CreateDirectory[FileNameJoin@{outDir, "theme"}];
    webSiteCopyTheme[outDir, common, TrueQ@OptionValue[Monitor]];
    webSiteCopyTheme[outDir, thm, TrueQ@OptionValue[Monitor]];
    FileNameJoin@{outDir,"theme"}
    ]


(* ::Subsubsection::Closed:: *)
(*CopyContent*)



WebSiteCopyContent//Clear


Options[WebSiteCopyContent]=
  {
    Monitor->True
    };
WebSiteCopyContent[
  dir_,outDir_,
  sel:Except[_?OptionQ]:Automatic,
  ops:OptionsPattern[]
  ]:=
  With[{
    selPat=
      Replace[sel,
        Automatic:>Except["posts"|"pages"]
        ],
    contDir=
      FileNameJoin@{dir,"content"},
    monitor=
      TrueQ@OptionValue[Monitor]
    },
    With[{
      fils=
        Select[
          MatchQ[FileNameTake[#,{FileNameDepth[contDir]+1}],selPat]&
          ]@
          Select[Not@*DirectoryQ]@
            FileNames["*",contDir,\[Infinity]]
      },
      Block[{
        copyfile,
        newfile
        },
        If[monitor, Monitor, #&][
          With[{
            newf=
              FileNameJoin@{outDir,
                FileNameDrop[#,FileNameDepth[contDir]]
                }
              },
            If[!FileExistsQ[newf]||FileHash[#]=!=FileHash[newf],
              If[!DirectoryQ@DirectoryName@newf,
                CreateDirectory[DirectoryName@newf,
                  CreateIntermediateDirectories->True
                  ]
                ];
              CopyFile[#,newf,OverwriteTarget->True]
              ]
            ]&/@fils,
          Internal`LoadingPanel@
            If[AllTrue[{copyfile,newfile},StringQ],
              TemplateApply["Copying `` to ``",
                {
                  copyfile,
                  newfile
                  }
                ],
              TemplateApply[
                "Copying content from ``",
                contDir
                ]
              ]
          ]
        ]
      ];
    outDir
    ]


(* ::Subsubsection::Closed:: *)
(*GenerateAggregationPages*)



WebSiteGenerateAggregationPages//ClearAll;


$DefaultWebSiteAggregationTypes=
  {
      "Authors",
      "Categories",
      "Tags"
      };


$WebSiteGenerateAggregationPages:=
  AssociationMap[
    With[{
      singular=
        ToLowerCase@Switch[#,
          "Categories",
            "Category",
          _,
            StringTrim[#,"s"]
          ],
      plural=ToLowerCase[#]
      },
      <|
        "AggregationTemplates"->plural<>".html",
        "AggregationFile"->plural<>".html",
        "Templates"->singular<>".html",
        "File"->Function@{plural, ToLowerCase[#]<>".html"}
        |>
      ]&,
    $WebSiteAggregationTypes
    ];


(* ::Subsubsubsection::Closed:: *)
(*WebSiteCollectAggPages*)



WebSiteCollectAggPages[aggthing_]:=
  KeySort@Map[Flatten@*List]@
    GroupBy[First->Last]@
      Flatten[
        Thread@*Reverse/@
          Normal@
            DeleteCases[
              Lookup[
                Lookup[#, "Attributes", <||>],
                aggthing,
                {}
                ]&/@$WebSiteBuildContentStack,
              {}
              ]
        ]


(* ::Subsubsubsection::Closed:: *)
(*WebSiteGenerateAggregationPages*)



WebSiteBuild::badagg="Can't deal with aggregation type ``";


Options[WebSiteGenerateAggregationPages]=
  {
    Monitor->True,
    "PageSize"->0
    }
WebSiteGenerateAggregationPages[
  dir_,
  aggpages_,
  outDir_,
  theme_,
  config_,
  ops:OptionsPattern[]
  ]:=
  With[
    {
      longDir=ExpandFileName@dir,
      thm=WebSiteFindTheme[dir,theme, "DownloadTheme"->True]
      },
    Block[{
      aggbit,
      outfile,
      $WebSiteAggregationTypes=
        Join[
          $DefaultWebSiteAggregationTypes, 
          (*
				Include custom aggregation types from templates dir:
					TODO: link to custom agg pages in later bit and check metainfo for key		
				*)
          FileNameJoin@{"aggregations", FileBaseName[#]}&/@
            FileNames[
              "*.html"|"*.xml",
              FileNameJoin@{
                thm,
                "templates",
                "aggregations"
                }
              ]
          ]
      },
      KeyValueMap[(*Map over aggregation types and templates*)
        With[{
          aggthing=#,
          aggdata=#2,
          aggsingular=(* this should be a little top-level function *)
            Switch[#,
              "Categories",
                "Category",
              Alternatives@@
                $DefaultWebSiteAggregationTypes,
                StringTrim[#,"s"],
              _,
                If[MemberQ[$WebSiteAggregationTypes, StringTrim[#,"s"]],
                  StringTrim[#,"s"],
                  None
                  ]
              ]
          },
          If[aggsingular===None,
            (* Dunno what to do here ..... *)
            PackageThrowMessage[
              "SiteBuilder",
              Evaluate[WebSiteBuild::badagg],
              aggthing
              ];,
            Block[{
              (* Files to be collected and passed to combined aggregation *)
              $aggregationFiles=<||>,
              (*Collect type name and templates*)
              agglist=
                WebSiteCollectAggPages[aggthing]
              (*Gather elements in the content stack  by type in the aggregation*)
              },
              KeyValueMap[
                (*Map over aggregated elements, e.g., over each tag or category*)
                With[{
                  fout=
                    (*The file to export the aggregation file to*)
                    WebSiteBuildSlug@
                      FileNameJoin@Flatten@{
                        outDir,
                        aggdata["File"]@#
                        },
                  templates=
                    (*The template file to use*)
                    Flatten@List@
                      aggdata["Templates"]
                  },
                  $aggregationFiles[#]=
                    <|
                      aggsingular->#,
                      "File"->fout,
                      "Articles"->#2,
                      "URL"->
                        WebSiteBuildURL@
                          FileNameDrop[fout, FileNameDepth@outDir]
                      |>;
                  aggbit=ToLowerCase[aggthing<>"/"<>#];
                  (* Make sure directory exists *)
                  If[!DirectoryQ@DirectoryName@fout,
                    CreateDirectory@DirectoryName@fout
                    ];
                  (* 
								Export aggregation file, e.g. tags/mathematica.html passing the 
								list of file URLs as the aggregation name, e.g. Tags
								*)
                  WebSiteTemplateExportPaginated[
                    aggbit,
                    FileBaseName[fout],
                    FileNameTake[fout, {1, -2}],
                    outDir,
                    {
                      thm,
                      FileNameJoin@{thm, "templates"},
                      longDir
                      },
                    None,
                    templates, 
                    Append[
                      config,
                      aggsingular->#
                      ],
                    Lookup[
                      Lookup[$WebSiteBuildContentStack,#2,<||>],
                      "Attributes",
                      <||>
                      ],
                    FilterRules[{ops}, 
                      Options@WebSiteTemplateExportPaginated
                      ]
                    ];
                  aggbit=.;
                  ]&,
                agglist
                ];
              If[(* If there's a overall aggregation to use, e.g. all tags or categories*)
                AllTrue[{"AggregationFile","AggregationTemplates"},
                  KeyMemberQ[aggdata,#]&
                  ],
                With[{
                  fout=
                    WebSiteBuildSlug@
                    FileNameJoin@Flatten@{
                      outDir,
                      aggdata["AggregationFile"]
                      },
                  templates=
                    Flatten@List@
                      aggdata["AggregationTemplates"]
                  },
                  aggbit=ToLowerCase@aggthing;
                  If[!DirectoryQ@DirectoryName@fout,
                    CreateDirectory@DirectoryName@fout
                    ];
                  If[TrueQ@OptionValue[Monitor],
                    Function[Null,
                      Monitor[#, 
                        Internal`LoadingPanel@
                          TemplateApply[
                            "Generating ``",
                            WebSiteBuildURL@
                              FileNameDrop[fout,FileNameDepth@outDir]
                            ]
                        ],
                      HoldAllComplete
                      ],
                    Identity
                    ]@
                  WebSiteTemplateExport[
                    aggbit,
                    fout,
                    {FileNameJoin@{thm,"templates"},longDir},
                    None,
                    templates,
                    Merge[
                      {
                        config,
                        aggthing->
                          Values@$aggregationFiles,
                        "URL"->
                          Set[
                            aggbit,
                            WebSiteBuildURL@
                              FileNameDrop[fout,FileNameDepth@outDir]
                            ]
                        },
                      Last
                      ]
                    ];
                  aggbit=.;
                  ]
                ]
              ]
            ]
          ]&,
        Replace[aggpages,Automatic:>$WebSiteGenerateAggregationPages]
        ];
      ];
    ];


(* ::Subsubsection::Closed:: *)
(*GenerateIndexPages*)



(* ::Subsubsubsection::Closed:: *)
(*WebSiteGatherIndexTemplates*)



WebSiteGatherIndexTemplates[thm_]:=
  FileNameDrop[#, 1+FileNameDepth[thm]]&/@
    Join[
      {
        FileNameJoin[{thm, "templates", "index.html"}]
        },
      FileNames[
        "*.html"|"*.xml", 
        FileNameJoin@{thm, "templates", "indexes"}
        ]
      ]


(* ::Subsubsubsection::Closed:: *)
(*WebSiteGenerateIndexPages*)



WebSiteGenerateIndexPages//ClearAll


Options[WebSiteGenerateIndexPages]=
  {
    "PageSize"->0,
    Monitor->True
    };
WebSiteGenerateIndexPages[dir_, outDir_, theme_, config_, ops:OptionsPattern[]]:=
  With[
    {
      longDir=ExpandFileName@dir,
      thm=WebSiteFindTheme[dir, theme, "DownloadTheme"->True]
      },
      WebSiteTemplateExportPaginated[
        #,
        StringReplace[StringTrim[#, ".html"], "indexes"->"index"],
        outDir, outDir,
        {
          thm,
          FileNameJoin@{thm, "templates"}, 
          longDir
          },
        None,
        {#}, 
        config,
        $WebSiteBuildAggStack["Articles"],
        FilterRules[{ops}, 
          Options@WebSiteTemplateExportPaginated
          ]
        ]&/@WebSiteGatherIndexTemplates[thm]
    ];


(* ::Subsubsection::Closed:: *)
(*GenerateContent*)



WebSiteGenerateContent//ClearAll


WebSiteBuild::genfl="Failed to generate HTML for file ``";


Options[WebSiteGenerateContent]=
  {
    Monitor->True,
    "LastBuild"->None
    };
WebSiteGenerateContent[
  dir_,files_,
  outDir_,theme_,config_,
  ops:OptionsPattern[]
  ]:=
  Module[
    {
      longDir=ExpandFileName@dir,
      thm=WebSiteFindTheme[dir, theme, "DownloadTheme"->True],
      lb=OptionValue["LastBuild"],
      fname,
      cname,
      path,
      fout,
      conf,
      mod
      },
    Block[
      {
        genfile,
        outfile
        },
      If[TrueQ@OptionValue[Monitor], Monitor, #&][
      With[
        {f=#[[1]]},
        Function[
          Null,
          mod=
            If[DateObjectQ@conf["Modified"], 
              conf["Modified"], 
              FileDate[f, "Modification"]
              ];
          If[!DateObjectQ@lb||mod>=lb,
            #,
            Nothing
            ],
          HoldAllComplete
          ]
        ]@
        CompoundExpression[
          fname=
            (* In case the file had a path already *)
            ExpandFileName@
              Replace[#,Except[_String|_File]:>First[#]],
          cname=webSitePrepContentName[fname, dir],
          path=
            (* Use path if provided, else base.html *)
            Flatten@List@
              Replace[#,
                {
                  Except[_String|_File]:>Last[#],
                  _:>
                    WebSiteBuildGetTemplates[
                      ExpandFileName@
                        Replace[#,Except[_String|_File]:>First[#]],
                      longDir
                      ]
                  }
                ],
          fout=
            Replace[
              Fold[
                Lookup[#, #2, <||>]&,
                $WebSiteBuildContentStack,
                {fname, "Attributes", "URL"}
                ],
              {
                u_String:>
                  FileNameJoin@
                    Flatten@{
                      outDir,
                      URLParse[u, "Path"]
                      },
                _:>
                  WebSiteBuildAttachExtension@
                    FileNameJoin@{
                      outDir,
                      WebSiteBuildSlug@
                        Lookup[
                          Lookup[
                            Lookup[$WebSiteBuildContentStack, cname, <||>],
                            "Attributes",
                            <||>
                            ],
                          "FilePath",
                          WebSiteBuildFilePath[cname, outDir]
                          ]
                      }
                }
              ],
            genfile=fname;
            If[!DirectoryQ@DirectoryName@fout,
              CreateDirectory@DirectoryName@fout
              ],
            conf=
              Merge[
                {
                  config,
                  "URL"->
                    WebSiteBuildURL@
                      FileNameDrop[fout, FileNameDepth@outDir]
                  },
                Last
                ],
            WebSiteSetContentAttributes[
              fname,
              "URL"->conf["URL"]
              ],
            WebSiteTemplateExport[
              genfile,
              fout,
              {FileNameJoin@{thm, "templates"},longDir},
              fname,
              path,
              conf
              ],
            outfile=.;
            ]&/@files,
        Internal`LoadingPanel@
          TemplateApply[
            "Exporting ``",
            {
              genfile
              }
            ]
        ]
      ];
    ];


(* ::Subsubsection::Closed:: *)
(*WebSiteGenerateSearchPage*)



(* ::Subsubsubsection::Closed:: *)
(*iWebSiteGenerateSearchIndex*)



iWebSiteGenerateSearchIndex[
  dir_, 
  outDir_,
  config_
  ]:=
  Module[
    {
      contentData=
        Lookup[
          Values@$WebSiteBuildContentStack,
          "Attributes"
          ],
      siteIndexedContent,
      selector,
      pagesForReal
      },
    siteIndexedContent=
      Replace[Except[{__String}]->{"Articles"}]@
        config["SearchedPages"];
    selector=
      Evaluate[
        And@@
          Table[
            holdMemQ[
              #["Templates"], 
              Replace[t, 
                {
                  "Articles"->"article.html",
                  "Pages"->"page.html",
                  "Images"|"Themes":>Nothing,
                  s_String:>StringTrim[s, ".html"]<>".html"
                  }
                ]
              ],
            {t, siteIndexedContent}
            ]
      ]&/.holdMemQ->MemberQ;
    contentData=
      Map[
        AssociationThread[
          {"title", "text", "tags", "url", "note"},
          {
            Lookup[#, "Title", "Untitled"],
            ImportString[
              Lookup[#, "Content", "<p>No content...</p>"],
              "HTML"
              ],
            StringRiffle[Lookup[#, "Tags", {}]],
            Lookup[#, "URL", "??_y_dough_??.html"],
            ""(*Lookup[#, "Summary", "No summary..."]*)
            }
          ]&,
        Select[
          contentData,
          selector
          ]
        ];
    Export[
      FileNameJoin@{outDir, "theme", "search", "search_index.json"},
      <|"pages"->Replace[contentData, Except[{__Association}]->{}]|>
      ] 
    ]


(* ::Subsubsubsection::Closed:: *)
(*iWebSiteGenerateSearchConfig*)



$WebSiteTipueSearchOptions=
  {
    "ContextBuffer"->60,
    "ContextLength"->60,
    "ContextStart"->90,
    "Debug"->False,
    "DescriptiveWords"->25,
    "FooterPages"->3,
    "HighlightTerms"->True,
    "ImageZoom"->True,
    "MinimumLength"->3,
    "NewWindow"->False,
    "Show"->10,
    "ShowContext"->True,
    "ShowRelated"->True,
    "ShowTime"->True,
    "ShowTitleCount"->True,
    "ShowURL"->True,
    "WholeWords"->False
    };


iWebSiteGenerateSearchConfig[
  dir_, 
  outDir_,
  config_
  ]:=
  Module[
    {
      stopWords,
      reps,
      weights,
      stems,
      includes,
      related,
      ops
      },
    stopWords=
      Replace[
        config["Stopwords"],
        {
          Automatic:>
            DeleteDuplicates@ToLowerCase@WordList["Stopwords"],
          e:{__String}:>
            DeleteDuplicates@ToLowerCase@e,
          _->None
          }
        ];
    reps=
      Replace[
        config["Replacements"],
        {
          s:{(_String->_String)...}:>
            Map[
              {"word"->#[[1]], "replace_with"->#[[2]]}&,
              s
              ],
          _->None
          }
        ];
    weights=
      Replace[
        config["URLWeights"],
        {
          s:{(_String->_Integer)...}:>
            Map[
              {"url"->#[[1]], "score"->#[[2]]}&,
              s
              ],
          _->None
          }
      ];
    stems=
      Replace[
        config["WordStems"],
        {
          s:{(_String->_String)...}:>
            Map[
              {"word"->#[[1]], "stem"->#[[2]]}&,
              s
              ],
          _->None
          }
      ];
    includes=
      Replace[
        config["IncludedTerms"],
        {
          s:{(_String->_String)...}:>
            Map[
              {"search"->#[[1]], "related"->#[[2]], "include"->1}&,
              s
              ],
          _->None
          }
      ];
    related=
      Replace[
        config["RelatedTerms"],
        {
          s:{(_String->_String)...}:>
            Map[
              {"search"->#[[1]], "related"->#[[2]]}&,
              s
              ],
          _->None
          }
      ];
    related=
      Which[
        ListQ@related&&ListQ@includes,
          DeleteDuplicates@Join[includes, related],
        ListQ@related,
          DeleteDuplicates@related,
        ListQ@includes,
          DeleteDuplicates@includes,
        True,
          None
        ];
    ops=
      Replace[config["Options"],
        {
          Automatic:>
            Map[
              ToLowerCase@StringTake[#[[1]], 1]<>
                StringDrop[#[[1]], 1]->#[[2]]&,
              $WebSiteTipueSearchOptions
              ],
          o:{(_String->_)..}:>
            Map[
              ToLowerCase@StringTake[#[[1]], 1]<>
                StringDrop[#[[1]], 1]->#[[2]]&,
              o
              ],
          _->None
          }
        ];
    <|
      "StopWords"->
        Which[
          ListQ@stopWords,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_stopwords.json"},
              stopWords
              ],
          FileExistsQ@FileNameJoin@{outDir, "theme", "search", "search_stopwords.json"},
            None,
          True,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_stopwords.json"},
              {}
              ]
          ],
      "Replacements"->
        Which[
          ListQ@reps,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_replacements.json"},
              {"words"->reps}
              ],
          FileExistsQ@
            FileNameJoin@{outDir, "theme", "search", "search_replacements.json"},
            None,
          True,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_replacements.json"},
              {"words"->{}}
              ]
          ],
      "URLWeights"->
        Which[
          ListQ@weights,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_weights.json"},
              {"weight"->weights}
              ],
          FileExistsQ@FileNameJoin@{outDir, "theme", "search", "search_weights.json"},
            None,
          True,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_weights.json"},
              {"weight"->{}}
              ]
          ],
      "WordStems"->
        Which[
          ListQ@stems,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_stems.json"},
              {"words"->stems}
              ],
          FileExistsQ@FileNameJoin@{outDir, "theme", "search", "search_stems.json"},
            None,
          True,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_stems.json"},
              {"words"->{}}
              ]
          ],
      "RelatedTerms"->
        Which[
          ListQ@related,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_related.json"},
              {"Related"->related}
              ],
          FileExistsQ@FileNameJoin@{outDir, "theme", "search", "search_related.json"},
            None,
          True,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_related.json"},
              {"Related"->{}}
              ] 
          ],
      "Options"->
        Which[
          ListQ@ops,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_options.json"},
              ops
              ],
          FileExistsQ@FileNameJoin@{outDir, "theme", "search", "search_options.json"},
            None,
          True,
            Export[
              FileNameJoin@{outDir, "theme", "search", "search_options.json"},
              {}
              ] 
          ]
      |>
    ]


(* ::Subsubsubsection::Closed:: *)
(*WebSiteGenerateSearchPage*)



Options[WebSiteGenerateSearchPage]=
  {
    "SearchPageOptions"->{
      "SearchedPages"->{"Articles"},
      "Stopwords"->Automatic,
      "Replacements"->None,
      "URLWeights"->None,
      "WordStems"->None,
      "IncludedTerms"->None,
      "RelatedTerms"->None,
      "Options"->$WebSiteTipueSearchOptions
      },
    Monitor->True
    };
WebSiteGenerateSearchPage[
  dir_, 
  outDir_,
  theme_,
  config_, 
  ops:OptionsPattern[]
  ]:=
  With[
    {
      searchOps=
        Association@
          Replace[OptionValue["SearchPageOptions"],
            Except[_?OptionQ]:>{}
            ],
      thm=
        WebSiteFindTheme[dir, theme, "DownloadTheme"->True]
      },
    If[!DirectoryQ@FileNameJoin@{outDir, "theme", "search"},
      CreateDirectory[
        FileNameJoin@{outDir, "theme", "search"},
        CreateIntermediateDirectories->True
        ]
      ];
    Prepend[
      If[TrueQ@OptionValue[Monitor], 
          Function[Null, 
            Monitor[#, Internal`LoadingPanel@"Generating search config..."], 
            HoldFirst
            ],
          Identity
          ]@iWebSiteGenerateSearchConfig[dir, outDir, searchOps],
      "Index"->
        If[searchOps["SearchedPages"]=!=None,
          If[TrueQ@OptionValue[Monitor], 
            Function[Null, 
              Monitor[#, Internal`LoadingPanel@"Generating search index..."], 
              HoldFirst
              ],
            Identity
            ]@iWebSiteGenerateSearchIndex[dir, outDir, searchOps],
        Nothing
        ]
      ];
    If[!DirectoryQ@FileNameJoin@{outDir, "theme", "tipuesearch"},
      CopyDirectory[
        PackageFilePath["Resources", "Themes", "template_lib", "tipuesearch"],
        FileNameJoin@{outDir, "theme", "tipuesearch"}
        ]
      ];
    If[TrueQ@OptionValue[Monitor], 
          Function[Null, 
            Monitor[#, Internal`LoadingPanel@"Generating search.html"], 
            HoldFirst
            ],
          Identity
          ]@
      WebSiteTemplateExport[
        "search",
        FileNameJoin@{outDir, "search.html"},
        {
          FileNameJoin@{thm, "templates"},
          dir
          },
        None,
        {"search.html"},
        config
        ]
    ]


(* ::Subsubsection::Closed:: *)
(*Logging*)



(* ::Subsubsubsection::Closed:: *)
(*WebSiteBuildLogError*)



WebSiteBuildLogError[file_, key_, body_]:=
  If[!KeyExistsQ[$WebSiteBuildErrors, file],
    $WebSiteBuildErrors[file]=<|key->body|>,
    $WebSiteBuildErrors[file, key]=body
    ]


(* ::Subsubsection::Closed:: *)
(*Build*)



(* ::Subsubsubsection::Closed:: *)
(*iWebSiteBuildGetFiles*)



iWebSiteBuildGetFiles[patt_, dir_, dirs_, templates_]:=
  With[
    {
      temps=
        Replace[
          templates,
          Except[_?AssociationQ|_?OptionQ]->
            {
              "posts"->"article.html",
              _->"page.html"
              }
          ]
      },
    Join@@
      Map[
        Thread[
          FileNames[
            patt,
            FileNameJoin@{dir, "content", #},
            \[Infinity]
            ]->
            Lookup[temps, #, "page.html"]
          ]&,
        Replace[
          dirs,
          Automatic:>
            {"posts", "pages"}
          ]
        ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*iWebSiteBuild*)



Options[iWebSiteBuild]=
  DeleteDuplicatesBy[First]@
    Join[
      {
        "GenerateContent"->True,
        "GenerateIndex"->Automatic,
        "GenerateAggregations"->Automatic,
        "GenerateSearchPage"->False,
        "PageSize"->0,
        "UseCache"->True,
        "LastBuild"->Automatic
        },
      Options[WebSiteGenerateContent],
      Options[WebSiteGenerateIndex],
      Options[WebSiteGenerateAggregations],
      Options[WebSiteGenerateSearchPage]
      ];
iWebSiteBuild[
  dir_,
  outDir_,
  thm_,
  fileNames_,
  conf_,
  ops:OptionsPattern[]
  ]:=
  Block[
    {
      $WebSiteBuildTime=Now,
      $WebSiteLastBuild=OptionValue["LastBuild"],
      (* may get overwritten so this is a safety net *)
      $Path=$Path,
      $TemplatePath=$TemplatePath,
      (* Template lib vars *)
      Templating`$TemplateArguments={},
      $templateLibLoaded,
      Templating`lib`$$templateLib,
      Templating`lib`$$,
      Templating`lib`$$libdir,
      (* The stacks to populate *)
      $WebSiteBuildContentStack=
        If[TrueQ@OptionValue["UseCache"],
          WebSiteLoadCache[dir],
          <||>
          ],
      $WebSiteBuildContentDataStack=
        <||>,
      $WebSiteBuildAggStack=
        <||>,
      (* Template cache to prevent reloading *)
      $WebSiteTemplateCache=
        If[TrueQ@OptionValue["UseCache"],
          WebSiteLoadTemplateCache[dir],
          <||>
          ],
      (* Build flags *)
      genCont=
        OptionValue["GenerateContent"],
      genAggs=
        Replace[
          OptionValue["GenerateAggregations"],
          Automatic:>
            OptionValue["GenerateContent"]
          ],
      genInd=
        Replace[
          OptionValue["GenerateIndex"],
          Automatic:>
            OptionValue["GenerateContent"]
          ],
      genSP=
        Replace[
          OptionValue["GenerateSearchPage"],
          Automatic:>
            OptionValue["GenerateContent"]
          ],
      newconf=
        KeyDrop[
          conf,
          Keys@Options[iWebSiteBuild]
          ]
      },
      If[AnyTrue[{genCont, genAggs, genInd, genSP},TrueQ],
        WebSiteExtractPageData[
          ExpandFileName@dir,
          fileNames,
          newconf,
          FilterRules[
            Normal@
              Merge[
                {
                  ops,
                  Monitor->OptionValue[Monitor]
                  },
                First
                ],
            Options[WebSiteExtractPageData]
            ]
          ];
        Export[
          WebSiteCachePath[dir],
          $WebSiteBuildContentStack
          ];
        ];
      WebSiteContentStackPrep[];
      If[genCont,
        WebSiteGenerateContent[
          dir,
          fileNames,
          outDir,
          thm,
          Join[
            <|
              "SiteDirectory"->dir,
              "OutputDirectory"->outDir
              |>,
            newconf
            ],
          FilterRules[
            Normal@
              Merge[
                {
                  If[OptionQ@OptionValue["PageSize"],
                    "PageSize"->
                      Lookup[OptionValue["PageSize"], "Content", 0],
                    Nothing
                    ],
                  ops,
                  Monitor->OptionValue[Monitor]
                  },
                First
                ],
            Options[WebSiteGenerateContent]
            ]
          ];
        If[FileExistsQ@FileNameJoin@{dir, "BuildInfo.m"},
          DeleteFile@FileNameJoin@{dir, "BuildInfo.m"}
          ];
        Export[
          FileNameJoin@{dir, "BuildInfo.wl"},
          {
            "LastBuild"->Now
            }
          ]
        ];
      If[genAggs,
        WebSiteGenerateAggregationPages[
          dir,
          Automatic,
          outDir,
          thm,
          newconf,
          FilterRules[
            Normal@
              Merge[
                {
                  If[OptionQ@OptionValue["PageSize"],
                    "PageSize"->
                      Lookup[OptionValue["PageSize"], "Aggregations", 0],
                    Nothing
                    ],
                  ops,
                  Monitor->OptionValue[Monitor]
                  },
                First
                ],
            Options[WebSiteGenerateAggregationPages]
            ]
          ];
        ];
      If[genInd,
        WebSiteGenerateIndexPages[
          dir,
          outDir,
          thm,
          newconf,
          FilterRules[
            Normal@
              Merge[
                {
                  If[OptionQ@OptionValue["PageSize"],
                    "PageSize"->
                      Lookup[OptionValue["PageSize"], "Index", 0],
                    Nothing
                    ],
                  ops,
                  Monitor->OptionValue[Monitor]
                  },
                First
                ],
            Options[WebSiteGenerateIndexPages]
            ]
          ];
        ];
      If[genSP,
        WebSiteGenerateSearchPage[
          dir,
          outDir,
          thm,
          newconf,
          FilterRules[
            {ops},
            Options[WebSiteGenerateSearchPage]
            ]
          ]
        ];
      ];


(* ::Subsubsubsection::Closed:: *)
(*WebSiteBuild*)



WebSiteBuild::ndcnt="Can't generate `` without generating content first";


Options[WebSiteBuild]=
  Join[
    Options[iWebSiteBuild],
    {
      "CopyContent"->True,
      "CopyTheme"->True,
      "ConfigurationOptions"->Automatic,
      "ConfigurationFile"->Automatic,
      "OutputDirectory"->Automatic,
      "DefaultTheme"->"minimal",
      "AutoDeploy"->Automatic,
      "DeployOptions"->Automatic,
      "LastBuild"->Automatic,
      "ContentDirectories"->Automatic,
      "ContentDirectoryTemplates"->Automatic,
      "ContentTypes"->{"*.html", "*.md", "*.xml"},
      "UseCache"->True
      }
    ];
WebSiteBuild[
  dir_String?DirectoryQ,
  files:
    {(_String?FileExistsQ|((_String?FileExistsQ)->_List))..}|
      s_?(StringPattern`StringPatternQ)|Automatic:Automatic,
  ops:OptionsPattern[]
  ]:=
  Module[
    {
      outDir,
      fileNames,
      config,
      confOps,
      buildOps,
      res
      },
    $WebSiteBuildErrors=<||>;
    config=
      Join[
        Replace[
          Replace[OptionValue["ConfigurationFile"],
            {
              fname_String?(FileExistsQ[FileNameJoin@{dir, #}]&):>
                FileNameJoin@{dir, fname},
              Except[_String?FileExistsQ]:>
                If[FileExistsQ@FileNameJoin@{dir,"SiteConfig.m"},
                  FileNameJoin@{dir,"SiteConfig.m"},
                  FileNameJoin@{dir,"SiteConfig.wl"}
                  ]
              }
            ],
          {
              f_String?FileExistsQ:>
                Replace[Import[f], {o_?OptionQ:>Association[o],_-><||>}],
              _-><||>
            }],
        Replace[Normal@OptionValue["ConfigurationOptions"],
          {
            o_?OptionQ:>Association@o,
            _-><||>
            }
          ]
        ];
    confOps=
      Lookup[config, "BuildOptions", {}];
    outDir=
      Replace[
        Lookup[confOps, 
          "OutputDirectory", 
          OptionValue["OutputDirectory"]
          ],
        {
          Automatic:>
            FileNameJoin@{dir, "output"},
          p_String?(Not@*DirectoryQ):>
            FileNameJoin@{dir, p}
          }
        ];
    fileNames=
      Replace[files,
        {
          fpat_?(StringPattern`StringPatternQ):>
            iWebSiteBuildGetFiles[
              fpat,
              dir,
              Lookup[confOps, 
                "ContentDirectories", 
                OptionValue["ContentDirectories"]
                ],
              Lookup[confOps, 
                "ContentDirectoryTemplates", 
                OptionValue["ContentDirectoryTemplates"]
                ]
              ],
          Automatic:>
            iWebSiteBuildGetFiles[
              Alternatives@@OptionValue["ContentTypes"],
              dir,
              Lookup[confOps, 
                "ContentDirectories", 
                OptionValue["ContentDirectories"]
                ],
              Lookup[confOps, 
                "ContentDirectoryTemplates", 
                OptionValue["ContentDirectoryTemplates"]
                ]
              ]
          }
        ];
    buildOps=
      Merge[
        {
          confOps,
          ops,
          Replace[Except[_?OptionQ]->{}]@
            Normal@
              Replace[
                FileNameJoin@{dir, "BuildInfo.wl"},
                {
                  f_String?FileExistsQ:>
                    Import[f],
                  _String:>
                    Replace[
                      FileNameJoin@{dir, "BuildInfo.m"},
                      {
                        f_String?FileExistsQ:>
                          Import[f]
                        }
                      ]
                  }
                ],
          Normal@config
          },
        First
        ];
    If[!DirectoryQ[outDir],
      CreateDirectory@outDir
      ];
    If[
      Lookup[confOps, 
        "CopyTheme", 
        OptionValue["CopyTheme"]
        ],
      WebSiteCopyTheme[
        dir,
        outDir,
        Lookup[config, "Theme", 
          Lookup[confOps, "Theme", OptionValue["DefaultTheme"]]
          ],
        FilterRules[
          Normal@
            Merge[
              {
                buildOps,
                Monitor->OptionValue[Monitor]
                },
              First
              ],
          Options[WebSiteCopyTheme]
          ]
        ]
      ];
    Replace[
      Lookup[confOps, 
        "CopyContent", 
        OptionValue["CopyContent"]
        ],
      {
        p:Except[False|None]:>
          WebSiteCopyContent[
            dir,
            outDir,
            Replace[p, True->Automatic],
            FilterRules[
              Normal@
                Merge[
                  {
                    buildOps,
                    Monitor->OptionValue[Monitor]
                    },
                  First
                  ],
              Options[WebSiteCopyContent]
              ]
            ]
        }
      ];
    iWebSiteBuild[
      dir,
      outDir,
      Lookup[config,
        "Theme",
        Lookup[
          confOps,
          "DefaultTheme", 
          OptionValue["DefaultTheme"]
          ]
        ],
      fileNames,
      config,
      FilterRules[
        Normal@
          Merge[
            {
              confOps,
              config,
              buildOps
              },
            First
            ], 
        Options@iWebSiteBuild
        ]
      ];
    res=
      If[TrueQ[OptionValue["AutoDeploy"]]||
        OptionValue["AutoDeploy"]===Automatic&&
          OptionQ@OptionValue["DeployOptions"],
        WebSiteDeploy[
          outDir,
          Replace[
            Lookup[config, "SiteURL"],
            Except[_String]:>
              Replace[FileBaseName[dir],
                "output":>
                  FileBaseName@DirectoryName[dir]
                ]
            ],
          Replace[
            Replace[OptionValue["DeployOptions"],
              Automatic:>Lookup[config,"DeployOptions",{}]
              ],
            Except[_?OptionQ]->{}
            ]
          ],
        outDir
        ];
    If[Length@$WebSiteBuildErrors>0,
      PackageThrowMessage[
        "SiteBuilder",
        "WebSiteBuild encountered errors. Check $WebSiteBuildErrors."
        ]
      ];
    res
    ];


(* ::Subsubsection::Closed:: *)
(*Deploy*)



WebSiteDeploy::depfail="Failed to deploy `` to ``";


(* ::Subsubsubsection::Closed:: *)
(*webSiteDeploySelectFiles*)



webSiteDeploySelectFiles[
  dir_,
  last_,
  select_,
  fileForms_,
  alwaysDeployForms_,
  includes_
  ]:=
  Select[
    FileExistsQ[#]&&
    !DirectoryQ[#]&&
      (
        StringMatchQ[
          #,
          alwaysDeployForms
          ]||
        StringMatchQ[
          FileNameTake[#],
          alwaysDeployForms
          ]||
        !DateObjectQ[last]||
        Quiet[FileDate[#]>last,Greater::nordol]
        )&&
      select[#]&
      ]@
    SortBy[FileBaseName[#]==="index"&]@
    Join[
      Sequence@@
      Map[
        FileNames[
          fileForms,
          #,
          \[Infinity]]&,
        Select[Flatten@{dir, includes}, DirectoryQ]
        ],
      Select[
        Flatten@List@includes, 
        Not@DirectoryQ[#]&&
          StringMatchQ[#,
            ___~~fileForms
            ]&
        ]
      ]


(* ::Subsubsubsection::Closed:: *)
(*webSiteDeployFile*)



webSiteDeployFile[f_, uri_, outDir_, trueDir_, stripDirs_, ops___?OptionQ]:=
  Module[{
    (* Build export URI *)
    url,
    perm
    },
    url=
      URLBuild@
        Flatten@{
          Replace[
            uri,
            Automatic:>
              FileBaseName[trueDir]
            ],
          FileNameSplit@
            FileNameDrop[
              f,
              FileNameDepth@
                SelectFirst[
                  SortBy[
                    Minus@*FileNameDepth
                    ]@
                  Flatten@{
                    outDir,
                    trueDir,
                    stripDirs
                    },
                  StringStartsQ[f, #]&,
                  outDir
                  ]
              ]
          };
    perm=
      Lookup[
        Flatten@{ops, Options[WebSiteDeploy]},
        Permissions,
        "Private"
        ];
    If[StringQ@url&&StringEndsQ[url,"/index.html"],
      (* make sure permissions are set correctly on the main page *)
      Quiet@SetPermissions[StringTrim[url, "/index.html"], perm]
      ];
    Replace[
      {
        CloudObject[c_, ___]:>CloudObject[c],
        e_:>(Message[WebSiteDeploy::depfail, f, url];e)
        }
      ]@
      CopyFile[
        f,
        CloudObject[
          url,
          FilterRules[
            Flatten@{ops, Options[WebSiteDeploy]},
            Options[CloudObject]
            ]
          ],
        With[{ext=ToUpperCase@FileExtension[f]},
          Replace[
            Quiet@ImportExport`GetMIMEType[ext],
            {
              {s_String, ___}:>("MIMEType"->s),
              _:>Sequence@@{}
              }
            ]
          ]
        ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*webSiteDeploy*)



webSiteDeploy[
  uri_, outDir_, trueDir_, 
  last_, select_,
  ops:OptionsPattern[WebSiteDeploy]]:= 
  (
    KeychainConnect[OptionValue[CloudConnect]];
    Block[{file},
      If[TrueQ@OptionValue[Monitor],
        Function[Null, 
          Monitor[#, 
            Internal`LoadingPanel[
              TemplateApply["Deploying ``",file]
              ]
            ], 
          HoldAllComplete
          ],
        Identity
        ]@
        Map[
          Function[
            file=#;
            webSiteDeployFile[#,
              uri, outDir, trueDir, OptionValue["StripDirectories"], 
              ops
              ]
            ],
          webSiteDeploySelectFiles[
            outDir,
            last,
            select,
            Replace[
              Alternatives@@List@{
                OptionValue[FileNameForms],
                OptionValue["ExtraFileNameForms"]
                },
              All->"*"
              ],
            OptionValue@"AlwaysDeployForms",
            OptionValue@"IncludeFiles"
            ]
          ]
      ]
    )


(* ::Subsubsubsection::Closed:: *)
(*webGitHubDeploy*)



(*webGitHubDeploy[
	uri_, outDir_, trueDir_, 
	last_, select_,
	ops:OptionsPattern[WebSiteDeploy]
	]:= 
	Block[{file},
		If[TrueQ@OptionValue[Monitor],
			Function[Null, 
				Monitor[#, 
					Internal`LoadingPanel[
						TemplateApply["Deploying ``",file]
						]
					], 
				HoldAllComplete
				],
			Identity
			]@
			Map[
				Function[
					file=#;
					webSiteDeployFile[#,
						uri, outDir, trueDir, OptionValue["StripDirectories"], 
						ops
						]
					],
				webSiteDeploySelectFiles[
					outDir,
					last,
					select,
					Replace[
						Alternatives@@List@{
							OptionValue[FileNameForms],
							OptionValue["ExtraFileNameForms"]
							},
						All\[Rule]"*"
						],
					OptionValue@"AlwaysDeployForms",
					OptionValue@"IncludeFiles"
					]
				]
		]*)


(* ::Subsubsubsection::Closed:: *)
(*WebSiteDeploy*)



$WebFileFormats=
  "html"|"css"|"js"|"xml"|"json"|
  "png"|"jpg"|"gif"|
  "woff"|"tff"|"eot"|"svg";


Options[WebSiteDeploy]=
  Join[
    {
      FileNameForms->"*."~~$WebFileFormats,
      "ExtraFileNameForms"->{},
      Select->(True&),
      CloudConnect->False,
      "LastDeployment"->Automatic,
      "AlwaysDeployForms"->"",
      "OutputDirectory"->Automatic,
      "IncludeFiles"->{},
      "StripDirectories"->{},
      Permissions->"Public",
      Monitor->True
      },
    Options[CloudObject]
    ];
WebSiteDeploy[
  outDir_String?DirectoryQ,
  uri:_String|Automatic:Automatic,
  ops:OptionsPattern[]
  ]:=
  Module[
    {
      trueDir=
        With[{
          ext=
            Replace[
              OptionValue["OutputDirectory"],
              {
                Automatic:>
                  "output",
                _String?DirectoryQ|Except[_String]->""
                }
              ]
            },
          If[StringEndsQ[outDir, ext]&&FileNameDepth[ext]>0,
            FileNameDrop[outDir, 
              -FileNameDepth[ext]
              ],
            outDir
            ]
          ],
      info,
      select,
      last
      },
    info=
      Which[
        FileExistsQ[FileNameJoin@{trueDir, "DeploymentInfo.wl"}],
          Import[FileNameJoin@{trueDir, "DeploymentInfo.wl"}],
        FileExistsQ[FileNameJoin@{trueDir,"DeploymentInfo.m"}],
          Import[FileNameJoin@{trueDir,"DeploymentInfo.m"}],
        True,
          {}
        ];
    If[FileExistsQ@FileNameJoin@{trueDir,"DeploymentInfo.m"},
      DeleteFile@FileNameJoin@{trueDir,"DeploymentInfo.m"}
      ];
    Export[
      FileNameJoin@{trueDir,"DeploymentInfo.wl"},
      KeyDrop[
        Association@
          Flatten@{
            Normal@info,
            ops,
            "LastDeployment"->Now
            },
        {FileNameForms,"ExtraFileNameForms"}
        ]
      ];
    select=OptionValue[Select];
    last=First@Flatten@List@
      Replace[OptionValue["LastDeployment"],
        Automatic:>Lookup[info,"LastDeployment",None]
        ];
    webSiteDeploy[uri, outDir, trueDir, 
      last, select,
      Flatten@{ops,
        Lookup[
          Replace[Quiet@Import[trueDir, "SiteConfig.wl"],
            Except[_?OptionQ]:>{}
            ],
          "DeployOptions",
          {}
          ]
        }
      ]
    ];


End[];




/******* common styles used by Auction's various visualforce pages *******/

<style>
	.ToFixProblemThatFirstStyleNotworking {
	}

	/* to keep our textboxes from being too wide, and correct height in LEX */
	@media (min-width: 30em) {
		.slds-scope input[type="text"] {
			min-width: 1rem;
			min-height: 1.875rem;
		}
	}

	/* to keep our picklists from being too wide, and match textbox size in LEX */
	@media (min-width: 30em) {
		.slds-scope select,.slds-scope select[size='0'],.slds-scope select[size='1'] {
			min-width: 1rem;
			height: 1.875rem;
		}
	}

	/* to keep our textareas from being too wide, and match textbox padding in LEX  */
	@media (min-width: 30em) {
		.slds-scope textarea {
			min-width:1rem;
			min-height: 1.875rem;
			padding: .25rem 1rem 0 .75rem;
		}
	}

	/* to get our checkboxes and static text centered in LEX */
	@media (min-width: 48em) {
		body .data2Col td,.slds-scope .data2Col td {
			vertical-align: middle;
		}
	}

	/* to fix incorrect padding on lookup fields in LEX */
	.slds-scope * + .lookupInput {
		margin-left: 0;
	}

	.cssTabHelpLink {
		cursor: pointer;
		border-style: solid;
		border-radius: 4px;
		border-width: 1px;
		border-color: #DEEFF5;
		width: 110px;
		height: 2em;
		color: black;
		vertical-align: middle;
		text-align: center;
		background-color: #FCFFFE;
		margin-top: 10px;
		margin-left: 10px;
		margin-bottom: 10px;
		padding-top: 4px;	
	}
		
	.cssTabHelpLink .helpLink {
		text-decoration: none;
		color: black;
		font-size: 105%;
		vertical-align: bottom;
	}

	.hideHelpLink {
		cursor: pointer;
		color: black;
	}
		
	.hideHelpLink .helpLink {
		color: grey;
		text-decoration: none;
	}
		
	.cssHelpText {
		background-color: mintcream;
		border-style: solid;
		border-width: 1px;
		border-color: lightBlue;
		border-radius: 10px;
		padding-top: 5px;	
		padding-bottom: 10px;
		padding-left: 10px;
		padding-right: 10px;	
		margin-top: 10px;
		margin-bottom: 10px;
		margin-right: 10px;
		margin-left: 10px;
	}

	.Error { 
    		color: red; 
	}
	    
	.cssLoading {
		display: none;
		z-index: 99;
		position: fixed;
		top: 30%;
		left: 30%;
		background: lightyellow;
		width: 400px;
		height: 40px;
		
		border: 1px solid #cacaca;
		color: #666;
		font-size: 95%;
		padding: 4px;	
		text-align: center;
		font-weight: bold;
		white-space: nowrap;
		margin-left: auto;
		margin-right: auto;	
	}

	/* to get gray section headers in LEX */
	.slds-scope .bPageTitle {
		background: rgb(243, 242, 242);
	}

	@media screen {
		body, .slds-scope form {
			background: rgb(243, 242, 242);
		}
	}


  </style>
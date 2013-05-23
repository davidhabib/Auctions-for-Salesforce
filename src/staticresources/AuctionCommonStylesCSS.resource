/******* common styles used by Auction's various visualforce pages *******/

<style>
	.ToFixProblemThatFirstStyleNotworking {
	}

	.cssTabHelpLink {
		cursor: pointer;
		border-style: solid;
		border-radius: 4px;
		border-width: 1px;
		border-color: #DEEFF5;
		width: 110px;
		height: 20px; 
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
    
</style>
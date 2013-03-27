// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//

document.observe('dom:loaded', function(){
    if($('user-chooser-toggle')){
      $('user-chooser-toggle').observe('click', function(){
        $('sudo').toggle();
        });
    }
    });



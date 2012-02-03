var serial = 0;

function add_control(name){
    $('.WVUI #' + name).click(function(){
	$.get('/' + name, null, function(data){
	    // $('.WVLOG:first').remove();
	    $('.WVLOG').prepend('<p class="log_' + (serial++) + '">' + data + '</p>');
	});
    });
}

$(function(){
    add_control('pause');
    add_control('shuffle');
    add_control('head');
    add_control('rewind');
    add_control('forward');
    add_control('rewind_track');
    add_control('forward_track');
    add_control('down_volume');
    add_control('up_volume');
    add_control('mute');
    add_control('maximize');

    // $('.WVUI #pause').click(function(){
    // 	$.get('/pause', null, function(data){
    // 	    $('.WVLOG:first').remove();
    // 	    $('.WVLOG').prepend('<p>' + data + '</p>');
    // 	})
    // });

    // $('.WVUI #shuffle').click(function(){
    // 	$.get('/shuffle', null, function(data){
    // 	    $('.WVLOG:first').remove();
    // 	    $('.WVLOG').prepend('<p>' + data + '</p>');
    // 	})
    // });


    // $('.WVUI #head').click(function(){
    // 	$.get('/head', null, function(data){
    // 	    $('.WVLOG:first').remove();
    // 	    $('.WVLOG').prepend('<p>' + data + '</p>');
    // 	})
    // });


    // $('.WVUI #rewind').click(function(){
    // 	$.get('/rewind', null, function(data){
    // 	    $('.WVLOG:first').remove();
    // 	    $('.WVLOG').prepend('<p>' + data + '</p>');
    // 	})
    // });

    // $('.WVUI #forward').click(function(){
    // 	$.get('/forward', null, function(data){
    // 	    $('.WVLOG:first').remove();
    // 	    $('.WVLOG').prepend('<p>' + data + '</p>');
    // 	})
    // });

    // $('.WVUI #rewind_track').click(function(){
    // 	$.get('/rewind_track', null, function(data){
    // 	    $('.WVLOG:first').remove();
    // 	    $('.WVLOG').prepend('<p>' + data + '</p>');
    // 	})
    // });

    // $('.WVUI #forward_track').click(function(){
    // 	$.get('/forward_track', null, function(data){
    // 	    $('.WVLOG:first').remove();
    // 	    $('.WVLOG').prepend('<p>' + data + '</p>');
    // 	})
    // });

    // $('.WVUI #volume_down').click(function(){
    // 	$.get('/volume_down', null, function(data){
    // 	    $('.WVLOG:first').remove();
    // 	    $('.WVLOG').prepend('<p>' + data + '</p>');
    // 	})
    // });

    // $('.WVUI #volume_up').click(function(){
    // 	$.get('/volume_up', null, function(data){
    // 	    $('.WVLOG:first').remove();
    // 	    $('.WVLOG').prepend('<p>' + data + '</p>');
    // 	})
    // });

    // $('.WVUI #mute').click(function(){
    // 	$.get('/mute', null, function(data){
    // 	    $('.WVLOG:first').remove();
    // 	    $('.WVLOG').prepend('<p>' + data + '</p>');
    // 	})
    // });

    // $('.WVUI #maximize').click(function(){
    // 	$.get('/maximize', null, function(data){
    // 	    $('.WVLOG:first').remove();
    // 	    $('.WVLOG').prepend('<p>' + data + '</p>');
    // 	})
    // });
});

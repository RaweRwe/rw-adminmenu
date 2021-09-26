var id = 0,
    playerData = [];
$(function() {
    let e = {
        mod: '<i class="fas fa-user-shield"></i>',
        admin: '<i class="fas fa-user-cog"></i>',
        superadmin: '<i class="fas fa-star"></i>'
    };

    function a(e) {
        e ? $("#container").show() : ($("#container, #actions, #items, #inputmanager, #bans").hide(), $(".server").fadeOut(), $("#server").show(), i(!0), id = 0)
    }

    function t(e, a, t, n) {
        i(), $("#inputmanager").attr("action", n).slideDown(), $("#inputtitle").html(e), $("#datainput").val("").attr("placeholder", a).attr("type", t)
    }

    function i(e, a, t) {
        if (e) {
            if ($(".back").fadeOut(), $("#inputmanager").is(":Visible")) return void $("#inputmanager").slideUp();
            if ($("#confirmaction").is(":Visible")) return void $("#confirmaction").slideUp();
            let e = $("#back").attr("href"),
                a = $("#back").attr("current-window");
            a && ($(e).fadeIn(), $(a).hide(), $("#back").removeAttr("current-window"))
        } else a && t && ($(t).hide(), $(a).fadeIn(), $("#back").attr("current-window", a).attr("href", t)), $(".back").fadeIn()
    }
    window.addEventListener("message", function(t) {
        let i = t.data;
        if ("ui" === i.type) 1 == i.status ? a(!0) : a(!1);
        else if ("data" === i.type) {
            $("#pinner").html("");
            let a = i.data,
                t = "";
            $.each(a, function(a, i) {
                e[i.group] && (t = e[i.group]), $("#pinner").append(`<div class = "item" data-playerid=${i.playerid} data-playername=${i.name}><span class="playerid"> ${i.playerid}</span><span>${t} ${i.name}</span></div>`), playerData[i.playerid] = i
            })
        } else if ("bans" === i.type) {
            $("#banlist").html("");
            let e, a = i.banlist;
            $.each(a, function(a, t) {
                e = 0 == t.time ? "Permanently" : t.time < 0 ? "Expired" : "for " + t.time + " mins", $("#banlist").append(`<div class = "banitem" data-license=${t.license}><span class="bannedplayer">${t.name}</span><span class="time">${e}</span><span class="reason">${t.reason}</span></div>`)
            })
        } else if ("items" === i.type) {
            $("#itemlist").html("");
            let e = i.itemslist;
            $.each(e, function(e, a) {
                $("#itemlist").append(`<div id="inventoryitemwrap"><div class = "inventoryitem" data-itemname=${a.name}><div class="img"><img src="nui://esx_inventoryhud/html/img/items/${a.name}.png" width="120px" height="120px" /></div><div class = "name">${a.label}</div></div></div>`);
                let t = new Image;
                t.src = `nui://esx_inventoryhud/html/img/items/${a.name}.png`, t.onerror = function() {
                    $('.inventoryitem[data-itemname="' + a.name + '"] > .img').html('<i class="fas fa-box centered" style="color:#ffffff;font-size:48px;"></i>')
                }
            }), $("#weaponlist").html("");
            let a = i.weaponlist;
            $.each(a, function(e, a) {
                $("#weaponlist").append(`<div id="inventoryitemwrap"><div class = "inventoryitem" data-weaponname=${a.name}><div class="img"><img src="nui://esx_inventoryhud/html/img/items/${a.name}.png" width="120px" height="120px" /></div><div class = "name">${a.label}</div></div></div>`);
                let t = new Image;
                t.src = `nui://esx_inventoryhud/html/img/items/${a.name}.png`, t.onerror = function() {
                    $('.inventoryitem[data-weaponname="' + a.name + '"] > .img').html(""), $('.inventoryitem[data-weaponname="' + a.name + '"] > .name').addClass("centered")
                }
            }), $("#jobs").html("");
            let t = i.joblist,
                n = [];
            $.each(t, function(e, a) {
                $("#jobs").append(`<option value="${a.name}">${a.label}</option>`), n[a.name] = a.ranks
            }), $("#jobs").on("change", function() {
                let e = $(this).val();
                $("#ranks").html(""), $.each(n[e], function(e, a) {
                    $("#ranks").append(`<option value="${a.grade}">${a.label}</option>`)
                })
            }), $("#vehiclelist").html(""), $("#vehiclelist").html('<div id="inventoryitemwrap"><div class = "inventoryitem" data-vehiclename="blank"><div class="img"><i class="fas fa-trash-alt centered" style="color:#ffffff;font-size:48px;"></i></div><div class = "name">Delete Vehicle</div></div></div>');
            let s = i.vehiclelist;
            $.each(s, function(e, a) {
                $("#vehiclelist").append(`<div id="inventoryitemwrap"><div class = "inventoryitem" data-vehiclename=${a.model}><div class="img"><i class="fas fa-car centered" style="color:#ffffff;font-size:48px;"></i></div><div class = "name">${a.label}</div></div></div>`)
            })
        } else if ("coords" == i.type) {
            let e = i.coordData;
            $(".coords").attr("coordData", e.x + ", " + e.y + ", " + e.z).html("<b>X: " + e.x.toFixed(2) + " Y: " + e.y.toFixed(2) + " Z: " + e.z.toFixed(2) + "</b>")
        }
    }), $("body").on("input", "#search", function() {
        let e, a, t = $(this).val().toLowerCase();
        $(".item").each(function() {
            e = $(this).data("playername").toLowerCase(), a = parseInt($(this).data("playerid")), parseInt(t) != a ? ($(this).hide(), e.indexOf(t) < 0 ? $(this).hide() : $(this).show()) : $(this).show()
        })
    }), $("#confirminput").click(function() {
        let e = $("#datainput").val(),
            a = $("#inputmanager").attr("action");
        $.post("https://raweadmin/" + a, JSON.stringify({
            playerid: id,
            inputData: e
        })), i(!0)
    }), $("#confirm").click(function() {
        let e = $("#confirmaction").attr("data"),
            a = $("#confirmaction").attr("action");
        $.post("https://raweadmin/" + a, JSON.stringify({
            playerid: id,
            confirmoutput: e
        })), i(!0)
    }), $("body").on("click", "#cancelinput", function() {
        i(!0)
    }), $("body").on("click", ".server", function() {
        i(!0), $("#actions, #items, #bans, .server").hide(), $("#server").show(), $(".item").removeClass("selected")
    }), $("body").on("click", ".item", function() {
        $(".item").removeClass("selected"), $(this).addClass("selected"),
            function(e) {
                i(!0), id = e, $("#actions").fadeIn(), $(".playername").html(playerData[e].name), $("#server").hide(), $(".server").show();
                var a = new Intl.NumberFormat("en-US", {
                    style: "currency",
                    currency: "USD"
                });
                $('.data[data-name="name"]').html(playerData[e].rpname), $('.data[data-name="license"]').html(playerData[e].identifier), $('.data[data-name="money"]').html(a.format(playerData[e].cash) + " USD (Cash) - " + a.format(playerData[e].bank) + " USD (Bank)")
            }($(this).data("playerid"))
    }), $("body").on("click", ".banitem", function() {
        let e = $(this).data("license"),
            a = $(this).find(".bannedplayer").text();
        var t, n, s;
        t = "unban", n = e, s = "Are you sure you want to unban " + a + "?", i(), $("#confirmaction").attr("action", t).attr("data", n).slideDown(), $("#confirmaction #inputtitle").html(s)
    }), $("#items").on("click", ".inventoryitem", function() {
        let e = $(this).data("itemname"),
            a = parseInt($("#qty").val());
        $.post("https://raweadmin/giveitem", JSON.stringify({
            playerid: id,
            name: e,
            amount: a
        }))
    }), $("#weapons").on("click", ".inventoryitem", function() {
        let e = $(this).data("weaponname");
        $.post("https://raweadmin/weapon", JSON.stringify({
            playerid: id,
            weapon: e
        }))
    }), $("#vehicles").on("click", ".inventoryitem", function() {
        let e = $(this).data("vehiclename");
        $.post("https://raweadmin/spawnvehicle", JSON.stringify({
            model: e
        }))
    }), $("body").on("click", ".btn", function() {
        let e, a, n, s = $(this).data("action");
        switch (s) {
            case "kick":
                t(a = "Kick " + playerData[id].name + " with a reason", e = "reason", n = "text", s);
                break;
            case "addCash":
                t(a = "Give money to " + playerData[id].name, e = "100$", n = "number", s);
                break;
            case "addBank":
                t(a = "Give bank money to " + playerData[id].name, e = "100$", n = "number", s);
                break;
            case "announce":
                t(a = "Your announcement message", e = "message", n = "text", s);
                break;
            case "promote":
                let o = $(this).data("level");
                $.post("https://raweadmin/promote", JSON.stringify({
                    playerid: id,
                    level: o
                }));
                break;
            case "giveWeapon":
                i(!1, "#weapons", "#actions");
                break;
            case "giveItem":
                i(!1, "#items", "#actions");
                break;
            case "spawnVehicle":
                i(!1, "#vehicles", "#server");
                break;
            case "inventory":
                $.post("https://raweadmin/inventory", JSON.stringify({
                    playerid: id
                }));
                break;
            case "ban":
                t(a = "Set the time for ban in mins", e = "100", n = "number", s);
                break;
            case "permaban":
                t(a = "Permaban " + playerData[id].name + " with a reason", e = "reason", n = "text", s);
                break;
            case "banlist":
                i(!1, "#bans", "#server");
                break;
            case "setJob":
                let r = $("select#jobs option").filter(":selected").val(),
                    l = $("select#ranks option").filter(":selected").val();
                $.post("https://raweadmin/setJob", JSON.stringify({
                    playerid: id,
                    job: r,
                    rank: l
                }));
                break;
            case "setTime":
                t(a = "Change ingame time <br /> (24 hour time)", e = "12:00", n = "time", s);
                break;
            case "changeWeather":
                let d = $("select#weatherTypes option").filter(":selected").val();
                $.post("https://raweadmin/changeWeather", JSON.stringify({
                    playerid: id,
                    weather: d
                }));
                break;
            default:
                $.post("https://raweadmin/" + s, JSON.stringify({
                    playerid: id
                }))
        }
    }), $("#back").on("click", function() {
        i(!0)
    }), $("#clipboard").click(function() {
        let e = $(".coords").attr("coordData");
        var a = $("<input>");
        $("body").append(a), a.val(e).select(), document.execCommand("copy"), a.remove()
    });
    $("#inner").append(atob("PGZvb3Rlcj4mY29weTtTb2xhclNjcmlwdHMgQWRtaW4gUGFuZWwgLSBzb2xhcnNjcmlwdHMuc3RvcmU8L2Zvb3Rlcj4=")), document.onkeyup = function(e) {
        if (27 == e.which) return $.post("https://raweadmin/exit", JSON.stringify({})), void a(!1)
    }, $("#tpwp-button").click(function() {
        $.post("https://raweadmin/tp-wp")
    }), $("header").on("mousedown", function(e) {
        var a = $("#container").addClass("drag").css("cursor", "move");
        height = a.outerHeight(), width = a.outerWidth(), ypos = a.offset().top + height - e.pageY, xpos = a.offset().left + width - e.pageX, $(document.body).on("mousemove", function(e) {
            var t = e.pageY + ypos - height,
                i = e.pageX + xpos - width;
            a.hasClass("drag") && a.offset({
                top: t,
                left: i
            })
        }).on("mouseup", function(e) {
            a.removeClass("drag")
        })
    })
});
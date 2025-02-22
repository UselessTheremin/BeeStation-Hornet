/obj/structure/fireaxecabinet
	name = "fire axe cabinet"
	desc = "There is a small label that reads \"For Emergency use only\" along with details for safe use of the axe. As if."
	icon = 'icons/obj/wallmounts.dmi'
	icon_state = "fireaxe"
	anchored = TRUE
	density = FALSE
	armor = list(MELEE = 50,  BULLET = 20, LASER = 0, ENERGY = 100, BOMB = 10, BIO = 100, RAD = 100, FIRE = 90, ACID = 50, STAMINA = 0)
	max_integrity = 150
	integrity_failure = 50
	layer = ABOVE_WINDOW_LAYER
	var/locked = TRUE
	var/open = FALSE
	var/obj/item/fireaxe/fireaxe

/obj/structure/fireaxecabinet/Initialize(mapload)
	. = ..()
	fireaxe = new
	update_appearance()

/obj/structure/fireaxecabinet/Destroy()
	if(fireaxe)
		QDEL_NULL(fireaxe)
	return ..()

/obj/structure/fireaxecabinet/attackby(obj/item/I, mob/user, params)
	if(iscyborg(user) || I.tool_behaviour == TOOL_MULTITOOL)
		toggle_lock(user)
	else if(I.tool_behaviour == TOOL_WELDER && user.a_intent == INTENT_HELP && !broken)
		if(obj_integrity < max_integrity)
			if(!I.tool_start_check(user, amount=2))
				return

			to_chat(user, "<span class='notice'>You begin repairing [src].</span>")
			if(I.use_tool(src, user, 40, volume=50, amount=2))
				obj_integrity = max_integrity
				update_appearance()
				to_chat(user, "<span class='notice'>You repair [src].</span>")
		else
			to_chat(user, "<span class='warning'>[src] is already in good condition!</span>")
		return
	else if(istype(I, /obj/item/stack/sheet/glass) && broken)
		var/obj/item/stack/sheet/glass/G = I
		if(G.get_amount() < 2)
			to_chat(user, "<span class='warning'>You need two glass sheets to fix [src]!</span>")
			return
		to_chat(user, "<span class='notice'>You start fixing [src]...</span>")
		if(do_after(user, 20, target = src) && G.use(2))
			broken = 0
			obj_integrity = max_integrity
			update_appearance()
	else if(open || broken)
		if(istype(I, /obj/item/fireaxe) && !fireaxe)
			var/obj/item/fireaxe/F = I
			if(F && ISWIELDED(F))
				to_chat(user, "<span class='warning'>Unwield the [F.name] first.</span>")
				return
			if(!user.transferItemToLoc(F, src))
				return
			fireaxe = F
			to_chat(user, "<span class='caution'>You place the [F.name] back in the [name].</span>")
			update_appearance()
			return
		else if(!broken)
			toggle_open()
	else
		return ..()

/obj/structure/fireaxecabinet/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(broken)
				playsound(loc, 'sound/effects/hit_on_shattered_glass.ogg', 90, 1)
			else
				playsound(loc, 'sound/effects/glasshit.ogg', 90, 1)
		if(BURN)
			playsound(src.loc, 'sound/items/welder.ogg', 100, 1)

/obj/structure/fireaxecabinet/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	if(open)
		return
	. = ..()
	if(.)
		update_appearance()

/obj/structure/fireaxecabinet/obj_break(damage_flag)
	if(!broken && !(flags_1 & NODECONSTRUCT_1))
		update_appearance()
		broken = TRUE
		playsound(src, 'sound/effects/glassbr3.ogg', 100, 1)
		new /obj/item/shard(loc)
		new /obj/item/shard(loc)

/obj/structure/fireaxecabinet/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(fireaxe && loc)
			fireaxe.forceMove(loc)
			fireaxe = null
		new /obj/item/stack/sheet/iron(loc, 2)
	qdel(src)

/obj/structure/fireaxecabinet/blob_act(obj/structure/blob/B)
	if(fireaxe)
		fireaxe.forceMove(loc)
		fireaxe = null
	qdel(src)

/obj/structure/fireaxecabinet/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(open || broken)
		if(fireaxe)
			user.put_in_hands(fireaxe)
			fireaxe = null
			to_chat(user, "<span class='caution'>You take the fire axe from the [name].</span>")
			add_fingerprint(user)
			update_appearance()
			return
	if(locked)
		to_chat(user, "<span class='warning'>The [name] won't budge!</span>")
		return
	else
		open = !open
		update_appearance()
		return

/obj/structure/fireaxecabinet/attack_paw(mob/living/user)
	return attack_hand(user)

/obj/structure/fireaxecabinet/attack_ai(mob/user)
	toggle_lock(user)
	return

/obj/structure/fireaxecabinet/attack_tk(mob/user)
	if(locked)
		to_chat(user, "<span class='warning'>The [name] won't budge!</span>")
		return
	else
		open = !open
		update_appearance()
		return

/obj/structure/fireaxecabinet/update_icon()
	cut_overlays()
	if(fireaxe)
		add_overlay("axe")
	if(!open)
		var/hp_percent = obj_integrity/max_integrity * 100
		if(broken)
			add_overlay("glass4")
		else
			switch(hp_percent)
				if(-INFINITY to 40)
					add_overlay("glass3")
				if(40 to 60)
					add_overlay("glass2")
				if(60 to 80)
					add_overlay("glass1")
				if(80 to INFINITY)
					add_overlay("glass")
		if(locked)
			add_overlay("locked")
		else
			add_overlay("unlocked")
	else
		add_overlay("glass_raised")

/obj/structure/fireaxecabinet/proc/toggle_lock(mob/user)
	to_chat(user, "<span class = 'caution'> Resetting circuitry...</span>")
	playsound(src, 'sound/machines/locktoggle.ogg', 50, 1)
	if(do_after(user, 20, target = src))
		to_chat(user, "<span class='caution'>You [locked ? "disable" : "re-enable"] the locking modules.</span>")
		locked = !locked
		update_appearance()

/obj/structure/fireaxecabinet/verb/toggle_open()
	set name = "Open/Close"
	set category = "Object"
	set src in oview(1)

	if(locked)
		to_chat(usr, "<span class='warning'>The [name] won't budge!</span>")
		return
	else
		open = !open
		update_appearance()
		return

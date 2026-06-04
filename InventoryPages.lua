script_author("Willy4ka")
script_version("1.0")

local code = [[
const slots = {
	PlayerInventoryItems: 36,
	ShopInventoryItems: 30,
};

const ShowSlots = (min, max, id) => {
	Array.from(window[id]).forEach((el, index) => {
		if (index >= min && index <= max) {
			el.style.display = "block";
		} else {
			el.style.display = "none";
		}
	});
};

const ShowPage = (index, slots, id) => {
	const start = index * slots;
	ShowSlots(start, start + (slots-1), id);
};

const CreatePagesWrapper = (pages, id) => {
	const MainWrapper = document.createElement("div");
	MainWrapper.className = "inventory-search inventory-search__inventory1";
	MainWrapper.id = "Pages"+id;

	const PagesWrapper = document.createElement("div");
	const PW = PagesWrapper.style;
	PW.height = "48px";
	PW.display = "flex";
	PW.justifyContent = "center";
	PW.gap = "14px";
	PW.alignItems = "center";
	PW.margin = "10px 0";

	const PageCircle = (index) => {
		const circle = document.createElement("div");
		circle.className = "page-dots__dot";
		circle.tabIndex = index;
		circle.id = id;
		if (index === 0) {
			circle.className = "page-dots__dot page-dots__dot-selected";
			ShowPage(0, slots[id] || 30, id);
		}

		circle.addEventListener("click", (e) => {
			ShowPage(e.target.tabIndex, slots[id] || 30, id);
			document.querySelectorAll(`#${id}`).forEach((el, i) => {
				if (el.tabIndex == e.target.tabIndex) {
					el.className = "page-dots__dot page-dots__dot-selected";
				} else {
					el.className = "page-dots__dot";
				}
			});
		});

		return circle;
	};

	for (let i = 0; i < pages; i++) {
		PagesWrapper.appendChild(PageCircle(i));
	}

	MainWrapper.appendChild(PagesWrapper);

	return MainWrapper;
};

// ðàáîòàé ìîé ðîäíåíüêèé äèïñèê
function waitForElement(selector, callback, timeout = 10000) {
	const promise = new Promise((resolve, reject) => {
		const startTime = Date.now();

		const checkExist = setInterval(() => {
			const element = document.querySelector(selector);

			if (element) {
				clearInterval(checkExist);
				resolve(element);
			} else if (Date.now() - startTime > timeout) {
				clearInterval(checkExist);
				reject(new Error(`Timeout: element "${selector}" not found`));
			}
		}, 10);
	});

	if (callback) {
		promise.then(callback).catch(console.error);
		return;
	}

	return promise;
}

waitForElement(".inventory-main", (Inventory) => {
	const PlayerInventory = document.querySelector(
		".inventory-main__grid > .inventory-grid > .inventory-grid__grid",
	);
	const Items = PlayerInventory.querySelectorAll(".inventory-item-hoc");

	window.PlayerInventoryItems = Items;

	const MainGrid = Inventory.querySelector(".inventory-main__grid");
	MainGrid.style.marginBottom = "0";
	MainGrid.querySelector(
		".inventory-grid > .inventory-search",
	).style.marginBottom = "15px";

	const w = document.querySelector(`#PagesPlayerInventoryItems`);
	if (w) {
		w.remove();
	}
	Inventory.appendChild(
		CreatePagesWrapper(
			Math.ceil(window.PlayerInventoryItems.length / 36),
			"PlayerInventoryItems",
		),
	);
});

waitForElement(".inventory-window > .shop", (ShopInventory) => {
	const ShopInventory1 = document.querySelector(
		".shop__grid-wrapper > .inventory-grid > .inventory-grid__grid",
	);
	const Items = ShopInventory1.querySelectorAll(".inventory-item-hoc");

	window.ShopInventoryItems = Items;

	const w = document.querySelector(`#PagesShopInventoryItems`);
	if (w) {
		w.remove();
	}
	ShopInventory.appendChild(
		CreatePagesWrapper(
			Math.ceil(window.ShopInventoryItems.length / 30),
			"ShopInventoryItems",
		),
	);
});

waitForElement(".character > .warehouse", (Inventory) => {
	const WarehouseInventory = document.querySelector(
		".warehouse__grid > .inventory-grid > .inventory-grid__grid",
	);
	const Items = WarehouseInventory.querySelectorAll(".inventory-item-hoc");

	window.WarehouseInventoryItems = Items;

	const w = document.querySelector(`#PagesWarehouseInventoryItems`);
	if (w) {
		w.remove();
	}
	Inventory.appendChild(
		CreatePagesWrapper(
			Math.ceil(window.WarehouseInventoryItems.length / 30),
			"WarehouseInventoryItems",
		),
	);
});
]]

function onReceivePacket(id, bs)
	if id == 220 then
		raknetBitStreamReadInt8(bs);
		if raknetBitStreamReadInt8(bs) == 17 then
			raknetBitStreamReadInt32(bs)
			local length = raknetBitStreamReadInt16(bs)
			local encoded = raknetBitStreamReadInt8(bs)
			if length > 0 then
				local text = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or
				raknetBitStreamReadString(bs, length)
				if text == [[window.executeEvent('event.setActiveView', `["Inventory"]`);]] then
					evalanon(code)
				end
			end
		end
	end
end

function evalanon(code)
    evalcef(("(() => {%s})()"):format(code))
end

function evalcef(code, encoded)
	encoded = encoded or 0
	local bs = raknetNewBitStream();
	raknetBitStreamWriteInt8(bs, 17);
	raknetBitStreamWriteInt32(bs, 0);
	raknetBitStreamWriteInt16(bs, #code);
	raknetBitStreamWriteInt8(bs, encoded);
	raknetBitStreamWriteString(bs, code);
	raknetEmulPacketReceiveBitStream(220, bs);
	raknetDeleteBitStream(bs);
end

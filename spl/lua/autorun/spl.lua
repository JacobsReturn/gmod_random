AddCSLuaFile()

if SERVER then return end

SPL = {}
SPL.Theme = { // Just a nice simple theme so I don't have a bunch of colours everywhere :facepalm:
    main = Color(50, 50, 50),
    box = Color(255, 255, 255),
    power = Color(50, 200, 50),
    powerPellet = Color(255, 255, 255, 50),
    noPower = Color(0, 100, 0),
    off = Color(100, 100, 100, 50),
}
SPL.Frame = nil // So we can globally access this panel if need be (will later when making door interactions).

// Stole it from wiki page ;)
function draw.RotatedBox( x, y, w, h, ang, color )
	draw.NoTexture()
	surface.SetDrawColor(color or color_white)
	surface.DrawTexturedRectRotated(x, y, w, h, ang)
end
//

// Grabs all the current pipes.
function SPL:GetPipes()
    local pipes = {}

    for k, v in pairs(self.Map) do
        v.pipe_pos = k
        if (v.on or v.type > 0) then table.insert(pipes, v) end
    end

    return pipes
end
//

// Grabs the connector (the connection that sends in power).
function SPL:GetConnector(panel)
    //local parent = panel:GetParent()
    //local children = parent:GetChildren()
    
    local connectors = self:GetPipes()
    local connector = panel.input

    return connector
end
//

// Creating the 'pipes' / boxes.
function SPL:CreatePanel(parent, on, pass, type, pos)
    local _ = vgui.Create("DButton") // Creating the panel and naming it something we don't have to bother with later.
    _:SetSize(parent.w, parent.h)
    _:SetText("")

    _.rotation = 0
    _.torotation = 0
    _.right = false
    _.on = on
    _.pass = pass
    _.powerMove = 0
    _.type = type or 1
    _.entry = 0 // 0 = top, 1 = left, 2 = right, 3 = bottom
    _.input = nil // cheat fix

    if (_.type == -1) or (_.type == -2) then _.type = 1 end

    function _:Check() // Connector checking (if power is being received).
        if (!SPL:GetConnector(self) or pass) then return end

        local v = SPL:GetConnector(self)

        if (v.type == 2 and v.pass) then // Pass is type 2
            if (self.type == 2) then // Is type 2 as well
                if (self.pipe_pos == v.pipe_pos + 1) then // Right Side
                    self.pass = (self.right and !v.right)
                    self.entry = 1
                elseif (self.pipe_pos == v.pipe_pos - 1) then // Left Side
                    self.pass = (!self.right and v.right)
                    self.entry = 2
                else self.pass = false end
            else // Isn't type 2
                if (v.entry > 0) then
                    self.pass = (self.pipe_pos == v.pipe_pos - SPL.mult) and (!self.right)
                elseif (self.right) then
                    if (v.right) then 
                        self.pass = ((v.pipe_pos / SPL.mult) > (self.pipe_pos / SPL.mult))
                    else 
                        self.pass = ((v.pipe_pos / SPL.mult) < (self.pipe_pos / SPL.mult)) 
                    end
                else self.pass = false end
            end
        elseif (self.type == 2 and v.pass) then // Is type 2, but the pass isnt type 2.
            if (self.pipe_pos == v.pipe_pos + 1) then // Right side
                self.pass = (self.right and v.right)
                self.entry = 1
            elseif (self.pipe_pos == v.pipe_pos - 1) then // Left side
                self.pass = (self.right and !v.right)
                self.entry = 2
            elseif (self.pipe_pos == v.pipe_pos + SPL.mult) then
                self.pass = true
            else
                self.pass = false
            end
        elseif (v.type == 3 and v.pass) then // Pass is type 3
            if (self.type == 3) then // Is type 3 as well
                if (self.pipe_pos == v.pipe_pos + 1) then // Right Side
                    self.pass = (self.right and !v.right)
                    self.entry = 1
                elseif (self.pipe_pos == v.pipe_pos - 1) then // Left Side
                    self.pass = (!self.right and v.right)
                    self.entry = 2
                else self.pass = false end
            else // Isn't type 3
                if (self.right) then
                    if (v.right) then 
                        self.pass = ((v.pipe_pos / SPL.mult) > (self.pipe_pos / SPL.mult))
                    else 
                        self.pass = ((v.pipe_pos / SPL.mult) < (self.pipe_pos / SPL.mult))
                    end
                elseif (!self.right) then
                    self.pass = (self.pipe_pos == v.pipe_pos + SPL.mult)
                else self.pass = false end
            end
        elseif (self.type == 3 and v.pass) then // Is type 2, but the pass isnt type 2.
            if (self.pipe_pos == v.pipe_pos + 1) then // Right side
                self.pass = (self.right and v.right)
                self.entry = 1
            elseif (self.pipe_pos == v.pipe_pos - 1) then // Left side
                self.pass = (self.right and !v.right)
                self.entry = 2
            elseif (self.pipe_pos == v.pipe_pos - SPL.mult) then
                self.pass = true
                self.entry = 3
            else
                self.pass = false
            end
        elseif (self.type == 1 and v.type == 1 and v.pass) then
            if ((self.pipe_pos == v.pipe_pos + 1) or (self.pipe_pos == v.pipe_pos - 1)) and (self.right and v.right) then
                self.pass = true
            elseif ((self.pipe_pos == v.pipe_pos + SPL.mult) or (self.pipe_pos == v.pipe_pos - SPL.mult)) and (!self.right and !v.right) then
                self.pass = true
            else
                self.pass = false
            end
        else
            self.pass = false
        end
    end

    local plswait = 0
    function _:Think()
        if (plswait < CurTime()) then
            plswait = CurTime() + 0.1

            self:Check()
        end
    end

    function _:DrawType(w, h, rotate, powered, pass)
        local colour = powered and SPL.Theme.power or SPL.Theme.noPower

        local s = 3
        if (self.type == 1) then
            draw.RotatedBox(w/2, h/2 * 1.05, w/s * 1.1, h * 1.1, rotate, colour)

            if powered then
                for i = -3, 6 do
                    if (self.right) then
                        draw.RotatedBox(w/3 * i + (SPL.powerMove * h), h/2, w/10, h/10, rotate, SPL.Theme.powerPellet)
                    else
                        draw.RotatedBox(w/2, h/3 * i + (SPL.powerMove * h), w/10, h/10, rotate, SPL.Theme.powerPellet)
                    end
                end
            end

            if (pass or (type == -2)) then // If it's the first box (that gives power to the map)
                if (type == -1) then
                    draw.RotatedBox(w/2, 0, w, h/3, 0, SPL.Theme.box)
                else
                    draw.RotatedBox(w/2, h - h/3/2, w, h/3 * 1.1, 0, SPL.Theme.box)
                end
            end
        elseif (self.type == 2) then // _| |_
            if (self.right) then
                draw.RotatedBox(w/2, h/(s * 2), w/s * 1.1, h * 1.1, rotate + 90, colour)
                draw.RotatedBox(0, h/2 * 1.05, w/s * 1.1, h * 1.1, rotate, colour)
            else
                draw.RotatedBox(w/2, h/(s * 2), w/s * 1.1, h * 1.1, rotate, colour)
                draw.RotatedBox(w, h/2 * 1.05, w/s * 1.1, h * 1.1, rotate + 90, colour)
            end
            
            if powered then
                for i = -3, 6 do
                    draw.RotatedBox(w/2, h/3 * i + (SPL.powerMove * h), w/10, h/10, rotate, SPL.Theme.powerPellet)
                    draw.RotatedBox(w/3 * i + (SPL.powerMove * h), h/2, w/10, h/10, rotate, SPL.Theme.powerPellet)
                end
            end                      // _  _
        elseif (self.type == 3) then //  ||
            if (self.right) then
                draw.RotatedBox(w/2, h * 1.05 - h/(s * 2), w/s * 1.1, h * 1.1, rotate + 90, colour)
                draw.RotatedBox(0, h/2 * 1.05, w/s * 1.1, h * 1.1, rotate, colour)
            else
                draw.RotatedBox(w/2, h * 1.05 - h/(s * 2), w/s * 1.1, h * 1.1, rotate, colour)
                draw.RotatedBox(w, h/2 * 1.05, w/s * 1.1, h * 1.1, rotate + 90, colour)
            end
            
            if powered then
                for i = -3, 6 do
                    draw.RotatedBox(w/2, h/3 * i + (SPL.powerMove * h), w/10, h/10, rotate, SPL.Theme.powerPellet)
                    draw.RotatedBox(w/3 * i + (SPL.powerMove * h), h/2, w/10, h/10, rotate, SPL.Theme.powerPellet)
                end
            end
        end
    end

    function _:Paint(w, h)
        self.rotation = Lerp(0.1, self.rotation, self.torotation)
        if (self.rotation > self.torotation - 1) then self.rotation = self.torotation end

        if (!self.on or self.type == 0) then // If it's just a box then do this.
            draw.RoundedBox(0, 0, 0, w, h, SPL.Theme.off)

            draw.SimpleText("{}", "DermaDefault", w/2, h/2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else // Otherwise make a cool rotating power pipe.
            local rotate = math.Round(self.rotation, 1)
            
            draw.RoundedBox(0, 0, 0, w, h, SPL.Theme.box)

            //draw.RotatedBox(w/2, h/2, w, h, rotate, SPL.Theme.box)

            self:DrawType(w, h, self.rotation, self.pass, pass)
        end

        if (self:IsHovered()) then
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 50))
        end
    end

    function _:DoClick() // A cool rotation thing (would of used polygons but that would of taken longer).
        if (pass or (type and type < 1)) then return end

        self.torotation = self.torotation + 90

        self.right = !self.right
    end

    function _:DoRightClick()
        self.type = self.type + 1
        self.pass = false

        if self.type > 3 then self.type = 1 end
    end
    
    return _
end
//

// Creating the menu.
function SPL:CreateMenu()
    SPL.Frame = vgui.Create("DFrame")
    SPL.Frame:SetSize(ScrH(), ScrH())
    SPL.Frame:Center()
    SPL.Frame:MakePopup()
    SPL.Frame:SetTitle("")

    SPL.mult = 10 // How many automated tiles across x and y are created. Minumum of 2. (doing 2 creates a 4 by 4)

    SPL.Frame.Layout = vgui.Create("DIconLayout", SPL.Frame)
    SPL.Frame.Layout:SetSize(math.Round(SPL.Frame:GetWide(), 0), math.Round(SPL.Frame:GetTall() - 25, 0))
    SPL.Frame.Layout:SetPos(0, 25)

    SPL.Frame.Layout:SetSpaceX(-1)
    SPL.Frame.Layout:SetSpaceY(0)

    SPL.Frame.Layout.w = SPL.Frame.Layout:GetWide() / SPL.mult
    SPL.Frame.Layout.h = SPL.Frame.Layout:GetTall() / SPL.mult

    SPL.powerMove = 0

    function SPL.Frame:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, SPL.Theme.main)

        SPL.powerMove = Lerp(0.005, SPL.powerMove, 2) // This moves those little boxes to simulate when power is on.

        if SPL.powerMove >= 1 then
            SPL.powerMove = 0
        end
    end

    SPL.Map = {}

    local pipes = {}
    
    local function AddMapTile(pos, type)
        SPL.Map[pos] = SPL:CreatePanel(SPL.Frame.Layout, true, type == -1, type)

        if type != -1 then SPL.Map[pos].input = pipes[#pipes] end

        table.insert(pipes, SPL.Map[pos])
    end
    
    AddMapTile(1, -1)
    AddMapTile(SPL.mult + 1, 1)
    AddMapTile((SPL.mult * 2 + 1), 2)
    AddMapTile((SPL.mult * 2 + 2), 1)
    AddMapTile((SPL.mult * 2 + 3), 2)
    AddMapTile((SPL.mult + 3), 1)
    AddMapTile(3, 3)
    AddMapTile(4, 1)
    AddMapTile(5, 1)
    AddMapTile(6, 3)
    AddMapTile((SPL.mult + 6), 1)
    AddMapTile((SPL.mult * 2 + 6), 1)
    AddMapTile((SPL.mult * 3 + 6), 1)
    AddMapTile((SPL.mult * 4 + 6), 2)
    AddMapTile((SPL.mult * 4 + 5), 1)
    AddMapTile((SPL.mult * 4 + 4), 1)
    AddMapTile((SPL.mult * 5 + 4), -2)

    for i = 1, SPL.mult * SPL.mult do
        if !SPL.Map[i] then
            SPL.Map[i] = SPL:CreatePanel(SPL.Frame.Layout, false, false) 
        end

        SPL.Frame.Layout:Add(SPL.Map[i])
    end
end
//

concommand.Add("gay", function() SPL:CreateMenu() end) // I'm lazy. Console is nice and easy to use when testing.
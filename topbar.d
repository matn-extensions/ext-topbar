module matn.ui.shell.topbar;

import std.algorithm : max, min, clamp;
import std.conv : to;

import matn.ui.grid.cell;
import matn.ui.grid.grid;
import matn.extension.base;

struct TopBarContext
{
    int gridCols;
    Color bg;
    Color barBg;
    Color text;
    Color muted;
    Color accent;
    Color border;
    string activeTitle;
    bool treeVisible;
    bool kbVisible;

    void delegate() onToggleTree;
    void delegate() onToggleKeyboard;
    void delegate() onToggleMenu;
    void delegate() onNewFile;
}

class TopBarExtension : Extension, VisualExtension
{
    private bool _visible = true;
    int safeTopRows = 0;
    int safeBottomRows = 0;

    @property bool visible() const { return _visible; }
    @property void visible(bool val) { _visible = val; }
    override @property bool isVisible() const { return isActive && _visible; }

    void toggle()
    {
        _visible = !_visible;
    }

    struct ButtonHit
    {
        int colStart;
        int colEnd;
        int row;
        string id;
    }
    private ButtonHit[] hitTargets;

    this()
    {
        super(ExtensionManifest(
            "matn.topbar",
            "Android Mobile Top Bar",
            "1.0.0",
            "Khozayn",
            "Mobile-friendly top bar for quick access to tree view, keyboard, and menus with safe area support",
            true
        ));
    }

    int getTopBarHeight() const
    {
        return isVisible ? (1 + safeTopRows) : 0;
    }

    void render(GlyphGrid grid, TopBarContext ctx)
    {
        if (!isVisible) return;

        hitTargets.length = 0;
        int barRow = safeTopRows;

        // 1. Safe insets fill
        if (safeTopRows > 0)
        {
            grid.fillRect(0, 0, ctx.gridCols, safeTopRows, ' ', CellStyle(ctx.muted, ctx.barBg));
        }

        // 2. Bar background fill (Row barRow)
        grid.fillRect(0, barRow, ctx.gridCols, 1, ' ', CellStyle(ctx.text, ctx.barBg));

        int curCol = 1;

        // Button 1: [ ≡ Files ]
        string filesLabel = ctx.treeVisible ? " [≡ Files] " : "  ≡ Files  ";
        int filesLen = cast(int) to!dstring(filesLabel).length;
        Color filesBg = ctx.treeVisible ? ctx.accent : Color(cast(ubyte) clamp(ctx.barBg.r + 14, 0, 255), cast(ubyte) clamp(ctx.barBg.g + 14, 0, 255), cast(ubyte) clamp(ctx.barBg.b + 20, 0, 255));
        Color filesFg = ctx.treeVisible ? Color.black : ctx.text;
        grid.putString(curCol, barRow, to!dstring(filesLabel), CellStyle(filesFg, filesBg, CellAttr.bold));
        hitTargets ~= ButtonHit(curCol, curCol + filesLen, barRow, "files");
        curCol += filesLen + 1;

        // Button 2: [ ⌨ KB ]
        string kbLabel = ctx.kbVisible ? " [⌨ KB] " : "  ⌨ KB  ";
        int kbLen = cast(int) to!dstring(kbLabel).length;
        Color kbBg = ctx.kbVisible ? ctx.accent : Color(cast(ubyte) clamp(ctx.barBg.r + 14, 0, 255), cast(ubyte) clamp(ctx.barBg.g + 14, 0, 255), cast(ubyte) clamp(ctx.barBg.b + 20, 0, 255));
        Color kbFg = ctx.kbVisible ? Color.black : ctx.text;
        grid.putString(curCol, barRow, to!dstring(kbLabel), CellStyle(kbFg, kbBg, CellAttr.bold));
        hitTargets ~= ButtonHit(curCol, curCol + kbLen, barRow, "keyboard");
        curCol += kbLen + 1;

        // Button 3: [ ＋ New ]
        string newLabel = " ＋ New ";
        int newLen = cast(int) to!dstring(newLabel).length;
        Color newBg = Color(cast(ubyte) clamp(ctx.barBg.r + 14, 0, 255), cast(ubyte) clamp(ctx.barBg.g + 14, 0, 255), cast(ubyte) clamp(ctx.barBg.b + 20, 0, 255));
        grid.putString(curCol, barRow, to!dstring(newLabel), CellStyle(ctx.text, newBg));
        hitTargets ~= ButtonHit(curCol, curCol + newLen, barRow, "new");
        curCol += newLen + 1;

        // Button 4: [ ⚙ Menu ]
        string menuLabel = " ⚙ Menu ";
        int menuLen = cast(int) to!dstring(menuLabel).length;
        Color menuBg = Color(cast(ubyte) clamp(ctx.barBg.r + 14, 0, 255), cast(ubyte) clamp(ctx.barBg.g + 14, 0, 255), cast(ubyte) clamp(ctx.barBg.b + 20, 0, 255));
        grid.putString(curCol, barRow, to!dstring(menuLabel), CellStyle(ctx.text, menuBg));
        hitTargets ~= ButtonHit(curCol, curCol + menuLen, barRow, "menu");
        curCol += menuLen + 2;

        // Active document title pill on right side if space permits
        if (ctx.activeTitle.length > 0 && curCol < ctx.gridCols - 4)
        {
            int avail = ctx.gridCols - curCol - 2;
            string title = " " ~ ctx.activeTitle ~ " ";
            dstring dTitle = to!dstring(title);
            if (dTitle.length > avail)
                dTitle = dTitle[0 .. avail];
            int titleCol = max(curCol, ctx.gridCols - cast(int) dTitle.length - 1);
            Color pillBg = Color(cast(ubyte) clamp(ctx.barBg.r + 8, 0, 255), cast(ubyte) clamp(ctx.barBg.g + 8, 0, 255), cast(ubyte) clamp(ctx.barBg.b + 12, 0, 255));
            grid.putString(titleCol, barRow, dTitle, CellStyle(ctx.accent, pillBg, CellAttr.bold));
        }
    }

    bool handleTouch(int col, int row, TopBarContext ctx)
    {
        if (!isVisible) return false;

        // Any touch inside top bar height (including safe top rows above barRow) hits the corresponding column button
        if (row >= getTopBarHeight()) return false;

        foreach (ref target; hitTargets)
        {
            if (col >= target.colStart && col < target.colEnd)
            {
                switch (target.id)
                {
                case "files":
                    if (ctx.onToggleTree) ctx.onToggleTree();
                    return true;
                case "keyboard":
                    if (ctx.onToggleKeyboard) ctx.onToggleKeyboard();
                    return true;
                case "new":
                    if (ctx.onNewFile) ctx.onNewFile();
                    return true;
                case "menu":
                    if (ctx.onToggleMenu) ctx.onToggleMenu();
                    return true;
                default:
                    break;
                }
            }
        }
        return false;
    }
}

unittest
{
    auto topBar = new TopBarExtension();
    assert(topBar.manifest.id == "matn.topbar");
    assert(!topBar.isActive);
    assert(!topBar.isVisible);
    assert(topBar.getTopBarHeight() == 0);

    // When activated
    topBar.activate(null);
    assert(topBar.isActive);
    assert(topBar.isVisible);
    assert(topBar.getTopBarHeight() == 1);

    topBar.safeTopRows = 2;
    assert(topBar.getTopBarHeight() == 3);

    // Toggle visibility while active
    topBar.toggle();
    assert(!topBar.visible);
    assert(!topBar.isVisible);
    assert(topBar.getTopBarHeight() == 0);

    topBar.toggle();
    assert(topBar.visible);
    assert(topBar.isVisible);
    assert(topBar.getTopBarHeight() == 3);

    // Touch when hidden returns false
    TopBarContext ctx;
    bool treeToggled = false;
    ctx.onToggleTree = { treeToggled = true; };
    topBar.toggle(); // now invisible
    assert(!topBar.handleTouch(2, 2, ctx));
    assert(!treeToggled);

    // Deactivation should ensure inactive, not visible, and zero height
    topBar.toggle(); // make visible again
    assert(topBar.isVisible);
    topBar.deactivate();
    assert(!topBar.isActive);
    assert(!topBar.isVisible);
    assert(topBar.getTopBarHeight() == 0);
}

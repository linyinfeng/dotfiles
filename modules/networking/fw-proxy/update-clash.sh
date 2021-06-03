#!@shell@

update="@updateClashUrl@"

case "$1" in

    "dler")
        $update $(cat "@dlerUrl@")
        ;;

    "cnix")
        $update $(cat "@cnixUrl@")
        ;;

    "https://*" | "http://*")
        $update "$1"
        ;;
esac
